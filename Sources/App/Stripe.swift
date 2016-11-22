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

final class Stripe {
    
    static let secretKey = "sk_test_6zSrUMIQfOCUorVvFMS2LEzn"
    static var encodedSecretKey: String {
        return secretKey.data(using: .utf8)!.base64EncodedString()
    }
    
    static let authorizationHeader: [HeaderKey : String] = ["Authorization" : "Basic \(Stripe.encodedSecretKey)"]
    static let baseURLString = "https://api.stripe.com/v1/"
    
    typealias Token = String
    
    static func post(_ resource: String, query: [String : String]) throws -> JSON {
        let response = try drop.client.post(resource, headers: Stripe.authorizationHeader, query: query)
        
        guard let json = try? response.json() else {
            throw Abort.custom(status: .internalServerError, message: response.description)
        }
        
        
    }
    
    static func createStripeCustomer(forUser user: inout Customer, withPaymentSource source: Token) throws -> Token {
        
        
        
        guard let json = try? response.json() else {
            
        }
        
        guard let customer_id = json["id"]?.string else {
            throw Abort.custom(status: .internalServerError, message: response.description)
        }
        
        user.stripe_id = customer_id
        try user.save()
        
        return customer_id
    }
    
    static func associate(paymentSource source: Token, withUser user: Customer) throws -> Token {
        
        precondition(user.stripe_id != nil, "User must have a stripe id.")
        
        let authString = "sk_test_6zSrUMIQfOCUorVvFMS2LEzn:".data(using: .utf8)!.base64EncodedString()
        let response = try drop.client.post("https://api.stripe.com/v1/customers/\(user.stripe_id!)/sources", headers: ["Authorization" : "Basic \(authString)"], query: ["source" : source])
        
        guard let json = try? response.json() else {
            throw Abort.custom(status: .internalServerError, message: response.description)
        }
        
        guard let card_id = json["id"]?.string else {
            throw Abort.custom(status: .internalServerError, message: response.description)
        }
        
        return card_id
    }
    
    static func createPlan(forBox box: inout Box) throws {
        precondition(box.plan_id == nil, "Box already had plan.")
        let planId = UUID().uuidString
        
        let parameters = ["id" : "\(planId)",
            "amount" : "\(Int(box.price * 100))",
            "currency" : "usd",
            "interval" : "month",
            "name" : box.name]
        
        let authString = "sk_test_6zSrUMIQfOCUorVvFMS2LEzn:".data(using: .utf8)!.base64EncodedString()
        let response = try drop.client.post("https://api.stripe.com/v1/plans", headers: ["Authorization" : "Basic \(authString)"], query: parameters)
        
        guard let json = try? response.json() else {
            throw Abort.custom(status: .internalServerError, message: response.description)
        }
        
        guard json["id"]?.string != nil else {
            throw Abort.custom(status: .internalServerError, message: response.description)
        }
        
        box.plan_id = planId
        try box.save()
    }
    
    static func createSubscription(forUser user: Customer, forBox box: Box, withFrequency frequency: Frequency = .monthly) throws -> String {
        
        precondition(user.stripe_id != nil, "User must have a stripe id.")
        precondition(box.plan_id != nil, "Box must have a plan id.")
        
        let authString = "sk_test_6zSrUMIQfOCUorVvFMS2LEzn:".data(using: .utf8)!.base64EncodedString()
        let response = try drop.client.post("https://api.stripe.com/v1/subscriptions", headers: ["Authorization" : "Basic \(authString)"], query: ["customer" : user.stripe_id!, "plan" : box.plan_id!])
        
        guard let json = try? response.json() else {
            throw Abort.custom(status: .internalServerError, message: response.description)
        }
        
        guard let subscription_id = json["id"]?.string else {
            throw Abort.custom(status: .internalServerError, message: response.description)
        }
        
        if frequency == .once {
            let response = try drop.client.delete("https://api.stripe.com/v1/subscriptions/\(subscription_id)", headers: ["Authorization" : "Basic \(authString)"], query: ["at_period_end" : true])
            
            guard let json = try? response.json() else {
                throw Abort.custom(status: .internalServerError, message: response.description)
            }
            
            guard let test = json["cancel_at_period_end"]?.bool, test else {
                throw Abort.custom(status: .internalServerError, message: response.description)
            }
        }
        
        return subscription_id
    }
    
    static func paymentMethods(forUser user: Customer) throws -> JSON {
        
        let authString = "sk_test_6zSrUMIQfOCUorVvFMS2LEzn:".data(using: .utf8)!.base64EncodedString()
        let response = try drop.client.get("https://api.stripe.com/v1/customers/\(user.stripe_id!)/sources?object=card", headers: ["Authorization" : "Basic \(authString)"])
        
        guard let json = try? response.json() else {
            throw Abort.custom(status: .internalServerError, message: response.description)
        }
        
        guard let cards = try json["data"]?.makeJSON() else {
            throw Abort.custom(status: .internalServerError, message: response.description)
        }
        
        return cards
    }
    
    static func information(forUser user: Customer) throws -> JSON {
        
        let authString = "sk_test_6zSrUMIQfOCUorVvFMS2LEzn:".data(using: .utf8)!.base64EncodedString()
        let response = try drop.client.get("https://api.stripe.com/v1/customers/\(user.stripe_id!)", headers: ["Authorization" : "Basic \(authString)"])
        
        guard let json = try? response.json() else {
            throw Abort.custom(status: .internalServerError, message: response.description)
        }
        
        return json
    }
}

