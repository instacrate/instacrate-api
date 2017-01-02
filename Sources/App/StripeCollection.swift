
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
        return try self.makeNode().makeResponse()
    }
}

class StripeCollection: RouteCollection, EmptyInitializable {

    required init() { }

    typealias Wrapped = HTTP.Responder

    func build<B: RouteBuilder>(_ builder: B) where B.Value == Wrapped {

        builder.group("stripe") { stripe in

            stripe.post("customer", String.self) { request, source in

                let customer = try request.customer()

                guard customer.stripe_id == nil else {
                    throw Abort.custom(status: .badRequest, message: "User \(customer.id!.int!) already has a stripe account.")
                }

                return try Stripe.shared.createNormalAccount(email: customer.email, source: source).makeResponse()
            }

            stripe.group("token") { token in

                token.post(String.self) { request, source in

                    guard let customer = try? request.customer() else {
                        throw Abort.custom(status: .forbidden, message: "Log in first.")
                    }

                    guard let id = customer.stripe_id else {
                        throw Abort.custom(status: .badRequest, message: "User \(customer.id!.int!) doesn't have a stripe account.")
                    }

                    return try Stripe.shared.associate(source: source, withStripe: id).makeResponse()
                }

                token.delete(String.self) { request, source in

                    guard let customer = try? request.customer() else {
                        throw Abort.custom(status: .forbidden, message: "Log in first.")
                    }

                    guard let id = customer.stripe_id else {
                        throw Abort.custom(status: .badRequest, message: "User \(customer.id!.int!) doesn't have a stripe account.")
                    }

                    return try Stripe.shared.delete(payment: source, from: id).makeResponse()
                }
            }

            stripe.group("vendor") { vendor in

                vendor.get("verification", String.self) { request, country_code in
                    guard let country = CountryCode(rawValue: country_code) else {
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
            }
        }
    }
}
