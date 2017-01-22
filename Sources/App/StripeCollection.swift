
//
//  StripeCollection.swift
//  subber-api
//
//  Created by Hakon Hanesand on 1/1/17.
//
//

import Foundation
import HTTP
import Routing
import Vapor
import Stripe

extension NodeConvertible {

    public func makeResponse() throws -> Response {
        return try Response(status: .ok, json: self.makeNode().makeJSON())
    }
}

class StripeCollection: RouteCollection, EmptyInitializable {

    required init() { }

    typealias Wrapped = HTTP.Responder

    func build<B: RouteBuilder>(_ builder: B) where B.Value == Wrapped {

        builder.group("stripe") { stripe in

            stripe.group("customer") { customer in

                customer.post("create", String.self) { request, source in

                    let customer = try request.customer()

                    guard customer.stripe_id == nil else {
                        throw Abort.custom(status: .badRequest, message: "User \(customer.id!.int!) already has a stripe account.")
                    }

                    return try Stripe.shared.createNormalAccount(email: customer.email, source: source, local_id: customer.id?.int).makeResponse()
                }

                customer.group("sources") { sources in

                    sources.post(String.self) { request, source in

                        guard let customer = try? request.customer() else {
                            throw Abort.custom(status: .forbidden, message: "Log in first.")
                        }

                        guard let id = customer.stripe_id else {
                            throw Abort.custom(status: .badRequest, message: "User \(customer.id!.int!) doesn't have a stripe account.")
                        }

                        return try Stripe.shared.associate(source: source, withStripe: id).makeResponse()
                    }

                    sources.delete(String.self) { request, source in

                        guard let customer = try? request.customer() else {
                            throw Abort.custom(status: .forbidden, message: "Log in first.")
                        }

                        guard let id = customer.stripe_id else {
                            throw Abort.custom(status: .badRequest, message: "User \(customer.id!.int!) doesn't have a stripe account.")
                        }

                        return try Stripe.shared.delete(payment: source, from: id).makeResponse()
                    }
                }
            }
            
            stripe.get("country", "verification", String.self) { request, country_code in
                guard let country = try? CountryCode(node: country_code) else {
                    throw Abort.custom(status: .badRequest, message: "\(country_code) is not a valid country code.")
                }
                
                return try Stripe.shared.verificationRequiremnts(for: country).makeNode().makeResponse()
            }

            stripe.group("vendor") { vendor in

                vendor.get("disputes") { request in
                    return try Stripe.shared.disputes().makeNode().makeResponse()
                }

                vendor.post("create", String.self) { request, source in
                    var vendor = try request.vendor()
                    let account = try Stripe.shared.createManagedAccount(email: vendor.contactEmail, source: source, local_id: vendor.id?.int)
                    
                    vendor.stripeAccountId = account.id
                    vendor.keys = account.keys
                    try vendor.save()
                    
                    return try vendor.makeResponse()
                }

                vendor.post("acceptedtos", String.self) { request, ip in
                    let vendor = try request.vendor()

                    guard let stripe_id = vendor.stripeAccountId else {
                        throw Abort.custom(status: .badRequest, message: "Missing stripe id")
                    }

                    return try Stripe.shared.acceptedTermsOfService(for: stripe_id, ip: ip).makeNode().makeResponse()
                }
                
                vendor.get("verification") { request in
                    let vendor = try request.vendor()
                    
                    guard let stripeAccountId = vendor.stripeAccountId else {
                        throw Abort.custom(status: .badRequest, message: "Vendor does not have stripe id.")
                    }
                    
                    let account = try Stripe.shared.vendorInformation(for: stripeAccountId)
                    let descriptions = try account.descriptionsForNeededFields()
                    return try Node(node: descriptions).makeResponse()
                }
                
                vendor.post("upload", String.self) { request, _uploadReason in
                    let vendor = try request.vendor()
                    
                    guard let uploadReason = try UploadReason(from: _uploadReason) else {
                        throw Abort.custom(status: .badRequest, message: "\(_uploadReason) is not an acceptable reason.")
                    }
                    
                    if uploadReason != .identity_document {
                        throw Abort.custom(status: .badRequest, message: "Currently only \(UploadReason.identity_document.rawValue) is supported")
                    }
                    
                    guard let multipart = request.multipart?.allItems.first, case let .file(file) = multipart.1 else {
                        throw Abort.custom(status: .badRequest, message: "Missing file to upload.")
                    }
                    
                    guard let type = file.type, let fileType = try FileType(from: type) else {
                        throw Abort.custom(status: .badRequest, message: "Misisng upload file type.")
                    }
                    
                    let fileUpload = try Stripe.shared.upload(file: file.data, with: uploadReason, type: fileType)
                    
                    guard let stripeAccountId = vendor.stripeAccountId else {
                        throw Abort.custom(status: .badRequest, message: "Vendor with id \(vendor.id?.int ?? 0) does't have a stripe acocunt yet. Call /vendor/create/{token_id} to create one.")
                    }
                    
                    return try Stripe.shared.updateAccount(id: stripeAccountId, parameters: ["legal_entity[verification][document]" : fileUpload.id]).makeResponse()
                }
            }
        }
    }
}
