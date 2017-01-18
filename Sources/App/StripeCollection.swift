
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

                    return try Stripe.shared.createNormalAccount(email: customer.email, source: source).makeResponse()
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

            stripe.group("vendor") { vendor in

                vendor.get("verification", String.self) { request, country_code in
                    guard let country = try? CountryCode(node: country_code) else {
                        throw Abort.custom(status: .badRequest, message: "\(country_code) is not a valid country code.")
                    }

                    return try Stripe.shared.verificationRequiremnts(for: country).makeNode().makeResponse()
                }

                vendor.get("disputes") { request in
                    return try Stripe.shared.disputes().makeNode().makeResponse()
                }

                vendor.post("customer", String.self) { request, source in
                    let vendor = try request.vendor()
                    return try Stripe.shared.createManagedAccount(email: vendor.contactEmail, source: source).makeNode().makeResponse()
                }

                vendor.post("acceptedtos", String.self) { request, ip in
                    let vendor = try request.vendor()

                    guard let stripe_id = vendor.stripeAccountId else {
                        throw Abort.custom(status: .badRequest, message: "Missing stripe id")
                    }

                    return try Stripe.shared.acceptedTermsOfService(for: stripe_id, ip: ip).makeNode().makeResponse()
                }
            }
        }
    }
}
