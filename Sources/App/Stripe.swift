//
//  Stripe.swift
//  subber-api
//
//  Created by Hakon Hanesand on 11/16/16.
//
//

import Foundation
import Vapor
import HTTP

class HTTPClient {

    let baseURLString: String

    init(urlString: String) {
        baseURLString = urlString
    }

    func get(_ resource: String, query: [String : CustomStringConvertible] = [:]) throws -> JSON {
        let response = try drop.client.get(baseURLString + resource, headers: Stripe.authorizationHeader, query: query)

        guard let json = try? response.json() else {
            throw Abort.custom(status: .internalServerError, message: response.description)
        }

        return json
    }

    func post(_ resource: String, query: [String : CustomStringConvertible] = [:]) throws -> JSON {
        let response = try drop.client.post(baseURLString + resource, headers: Stripe.authorizationHeader, query: query)

        guard let json = try? response.json() else {
            throw Abort.custom(status: .internalServerError, message: response.description)
        }

        return json
    }

    func delete(_ resource: String, query: [String : CustomStringConvertible] = [:]) throws -> JSON {
        let response = try drop.client.delete(baseURLString + resource, headers: Stripe.authorizationHeader, query: query)

        guard let json = try? response.json() else {
            throw Abort.custom(status: .internalServerError, message: response.description)
        }

        return json
    }
}

final class Stripe: HTTPClient {

    static let shared = Stripe()
    
    static let secretKey = "sk_test_6zSrUMIQfOCUorVvFMS2LEzn"
    static var encodedSecretKey: String {
        return secretKey.data(using: .utf8)!.base64EncodedString()
    }
    
    static let authorizationHeader: [HeaderKey : String] = ["Authorization" : "Basic \(Stripe.encodedSecretKey)"]

    typealias Token = String

    fileprivate init() {
        super.init(urlString: "https://api.stripe.com/v1/")
    }
    
    @discardableResult
    func createStripeCustomer(forUser user: inout Customer, withPaymentSource source: Token) throws -> String {
        let json = try post("customers", query: ["source" : source])
        
        guard let customer_id = json["id"]?.string else {
            throw Abort.custom(status: .internalServerError, message: json.makeNode().nodeObject?.description ?? "Fuck.")
        }
        
        user.stripe_id = customer_id
        try user.save()
        
        return customer_id
    }

    func createStripeCustomer(forVendor vendor: inout Vendor, withPaymentSource source: Token) throws -> String {
        let json = try post("accounts", query: ["managed" : true, "country" : "US", "email" : vendor.contactEmail])

        guard let account_id = json["id"]?.string else {
            throw Abort.custom(status: .internalServerError, message: json.makeNode().nodeObject?.description ?? "Fuck.")
        }

        vendor.stripeAccountId = account_id
        try vendor.save()

        return account_id
    }
    
    @discardableResult
    func associate(paymentSource source: Token, withCustomer user: Customer) throws -> Token {
        
        precondition(user.stripe_id != nil, "User must have a stripe id.")
        
        let json = try post("customers/\(user.stripe_id!)/sources", query: ["source" : source])
        
        guard let card_id = json["id"]?.string else {
            throw Abort.custom(status: .internalServerError, message: json.makeNode().nodeObject?.description ?? "Fuck.")
        }
        
        return card_id
    }
    
    func createPlan(forBox box: inout Box) throws {
        precondition(box.plan_id == nil, "Box already had plan.")
        let planId = UUID().uuidString
        
        let parameters = ["id" : "\(planId)",
                        "amount" : "\(Int(box.price * 100))",
                        "currency" : "usd",
                        "interval" : "month",
                        "name" : box.name]
        
        let json = try post("plans", query: parameters)
        
        guard json["id"]?.string != nil else {
            throw Abort.custom(status: .internalServerError, message: json.makeNode().nodeObject?.description ?? "Fuck.")
        }
        
        box.plan_id = planId
        try box.save()
    }
    
    @discardableResult
    func createSubscription(forUser user: Customer, forBox box: Box, withFrequency frequency: Frequency = .monthly) throws -> String {
        
        precondition(user.stripe_id != nil, "User must have a stripe id.")
        precondition(box.plan_id != nil, "Box must have a plan id.")
        
        let json = try post("subscriptions", query: ["customer" : user.stripe_id!, "plan" : box.plan_id!])
        
        guard let subscription_id = json["id"]?.string else {
            throw Abort.custom(status: .internalServerError, message: json.makeNode().nodeObject?.description ?? "Fuck.")
        }
        
        if frequency == .once {
            let json = try delete("/subscriptions/\(subscription_id)", query: ["at_period_end" : true])
        
            guard json["cancel_at_period_end"]?.bool == true else {
                throw Abort.custom(status: .internalServerError, message: json.makeNode().nodeObject?.description ?? "Fuck.")
            }
        }
        
        return subscription_id
    }
    
    func paymentMethods(forUser user: Customer) throws -> JSON {
        
        let json = try get("customers/\(user.stripe_id!)/sources", query: ["object" : "card"])
        
        guard let cards = try json["data"]?.makeJSON() else {
            throw Abort.custom(status: .internalServerError, message: json.makeNode().nodeObject?.description ?? "Fuck.")
        }
        
        return cards
    }
    
    func information(forCustomer user: Customer) throws -> JSON {
        return try get("customers/\(user.stripe_id!)")
    }
}

