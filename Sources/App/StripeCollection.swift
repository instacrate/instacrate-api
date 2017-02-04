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

extension Sequence where Iterator.Element == Bool {
    
    public func all() -> Bool {
        return reduce(true) { $0 && $1 }
    }
}

extension NodeConvertible {

    public func makeResponse() throws -> Response {
        return try Response(status: .ok, json: self.makeNode().makeJSON())
    }
}

extension Sequence where Iterator.Element == (key: String, value: String) {
    
    func reduceDictionary() -> [String : String] {
        return flatMap { $0 }.reduce([:]) { (_dict, tuple) in
            var dict = _dict
            dict.updateValue(tuple.1, forKey: tuple.0)
            return dict
        }
    }
}

fileprivate func stripeKeyPathFor(base: String, appending: String) -> String {
    if base.characters.count == 0 {
        return appending
    }
    
    return "\(base)[\(appending)]"
}

extension Node {
    
    var isLeaf : Bool {
        switch self {
        case .array(_), .object(_):
            return false
            
        case .bool(_), .bytes(_), .string(_), .number(_), .null:
            return true
        }
    }

    func collected() throws -> [String : String] {
        return collectLeaves(prefix: "")
    }
    
    private func collectLeaves(prefix: String) -> [String : String] {
        switch self {
        case let .array(nodes):
            return nodes.map { $0.collectLeaves(prefix: prefix) }.joined().reduceDictionary()
            
        case let .object(object):
            return object.map { $1.collectLeaves(prefix: stripeKeyPathFor(base: prefix, appending: $0)) }.joined().reduceDictionary()
            
        case .bool(_), .bytes(_), .string(_), .number(_):
            return [prefix : string ?? ""]
            
        case .null:
            return [:]
        }
    }
}

class StripeCollection: RouteCollection, EmptyInitializable {

    required init() { }

    typealias Wrapped = HTTP.Responder

    func build<B: RouteBuilder>(_ builder: B) where B.Value == Wrapped {

        builder.group("stripe") { stripe in
            
            stripe.group("coupons") { coupon in
                
                coupon.get(String.self) { request, code in
                    let query = try Coupon.query().filter("code", code)
                    return try query.first() ?? Response(status: .notFound, json: JSON(Node.string("Invalid coupon code.")))
                }
                
                coupon.post() { request in
                    guard let email: String = try request.json().node.extract("customerEmail") else {
                        throw Abort.custom(status: .badRequest, message: "missing customer email")
                    }
                    
                    let fullCode = UUID().uuidString
                    let code = fullCode.substring(to: fullCode.index(fullCode.startIndex, offsetBy: 8))
                    var coupon = try Coupon(node: ["code" : code, "discount" : 0.05, "customerEmail" : email])
                    
                    let _ = try Stripe.shared.createCoupon(code: coupon.code)
                    
                    try coupon.save()
                    return coupon
                }
            }

            stripe.group("customer") { customer in

                customer.group("sources") { sources in
                    
                    // TODO : double check

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
                    
                    sources.get() { request in
                        guard let customer = try? request.customer(), let stripeId = customer.stripe_id else {
                            throw Abort.badRequest
                        }
                        
                        let cards = try Stripe.shared.paymentInformation(for: stripeId).map { try $0.makeNode() }
                        return try Node.array(cards).makeResponse()
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

                vendor.post("create") { request in
                    var vendor = try request.vendor()
                    let account = try Stripe.shared.createManagedAccount(email: vendor.contactEmail, local_id: vendor.id?.int)
                    
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
                    return try account.descriptionsForNeededFields().makeResponse()
                }
                
                vendor.get("payouts") { request in
                    let vendor = try request.vendor()
                    
                    guard let secretKey = vendor.keys?.secret else {
                        throw Abort.custom(status: .badRequest, message: "Vendor is missing stripe id.")
                    }
                    
                    return try Stripe.shared.transfers(for: secretKey).makeNode().makeResponse()
                }
                
                vendor.post("verification") { request in
                    let vendor = try request.vendor()
                    
                    guard let stripeAccountId = vendor.stripeAccountId else {
                        throw Abort.custom(status: .badRequest, message: "Vendor does not have stripe id")
                    }
                    
                    let account = try Stripe.shared.vendorInformation(for: stripeAccountId)
                    let fieldsNeeded = account.filteredNeededFieldsWithCombinedDateOfBirth()
                    var node = try request.json().permit(fieldsNeeded).node
                    
                    if node.nodeObject?.keys.contains(where: { $0.hasPrefix("external_account") }) ?? false {
                        node["external_account.object"] = "bank_account"
                    }

                    if node["legal_entity.dob"] != nil {
                        guard let unix = node["legal_entity.dob"]?.string else { throw Abort.custom(status: .badRequest, message: "Could not parse unix time from updates)") }
                        guard let timestamp = Int(unix) else { throw Abort.custom(status: .badRequest, message: "Could not get number from unix : \(unix)") }
                        
                        let calendar = Calendar.current
                        let date = Date(timeIntervalSince1970: Double(timestamp))
                        
                        node["legal_entity.dob"] = nil
                        node["legal_entity.dob.day"] = .string("\(calendar.component(.day, from: date))")
                        node["legal_entity.dob.month"] = .string("\(calendar.component(.month, from: date))")
                        node["legal_entity.dob.year"] = .string("\(calendar.component(.year, from: date))")
                    }
                    
                    var updates: [String : String] = [:]
                    
                    try node.nodeObject?.forEach {
                        guard let string = $1.string else {
                            throw Abort.custom(status: .badRequest, message: "could not convert object at key \($0) to string.")
                        }
                        
                        var split = $0.components(separatedBy: ".")
                        
                        if split.count == 1 {
                            updates[$0] = string
                            return
                        }
                        
                        var key = split[0]
                        split.remove(at: 0)

                        key = key + split.reduce("") { $0 + "[\($1)]" }
                        
                        updates[key] = string
                    }
                    
                    return try Stripe.shared.updateAccount(id: stripeAccountId, parameters: updates).makeResponse()
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
