//
//  OrderCollection.swift
//  subber-api
//
//  Created by Hakon Hanesand on 10/10/16.
//
//


import Foundation
import Vapor
import HTTP
import Routing
import JSON
import Auth

final class Stripe {
    
    typealias Token = String
    
    static func createStripeCustomer(forUser user: inout User, withPaymentSource source: Token) throws -> Token {
        
        let authString = "sk_test_6zSrUMIQfOCUorVvFMS2LEzn:".data(using: .utf8)!.base64EncodedString()
        let json = try drop.client.post("https://api.stripe.com/v1/customers", headers: ["Authentication" : "Basic \(authString)"], query: ["source" : source]).json()
        
        guard let customer_id = json["id"]?.string else {
            throw Abort.custom(status: .internalServerError, message: json.string ?? "Unkown error.")
        }
        
        user.stripe_id = customer_id
        try user.save()
        
        return customer_id
    }
    
    static func associate(paymentSource source: Token, withUser user: User) throws -> Token {
        
        precondition(user.stripe_id != nil, "User must have a stripe id.")
        
        let authString = "sk_test_6zSrUMIQfOCUorVvFMS2LEzn:".data(using: .utf8)!.base64EncodedString()
        let json = try drop.client.post("https://api.stripe.com/v1/customers/\(user.stripe_id!)/sources", headers: ["Authentication" : "Basic \(authString)"], query: ["source" : source]).json()
        
        guard let card_id = json["id"]?.string else {
            throw Abort.custom(status: .internalServerError, message: json.string ?? "Unkown error.")
        }
        
        return card_id
    }
    
    static func createPlan(forBox box: Box) throws {
        precondition(box.plan_id == nil, "Box already had plan.")
        box.plan_id = UUID().uuidString
        
        let parameters = ["id" : "\(box.plan_id!)",
                          "amount" : "\(box.price * 100)",
                          "currency" : "usd",
                          "interval" : "monthly",
                          "name" : box.name]
        
        let authString = "sk_test_6zSrUMIQfOCUorVvFMS2LEzn:".data(using: .utf8)!.base64EncodedString()
        _ = try drop.client.post("https://api.stripe.com/v1/plans", headers: ["Authentication" : "Basic \(authString)"], query: parameters).json()
    }
    
    static func createSubscription(forUser user: User, forBox box: Box) throws -> String {
        let authString = "sk_test_6zSrUMIQfOCUorVvFMS2LEzn:".data(using: .utf8)!.base64EncodedString()
        let json = try drop.client.get("POST https://api.stripe.com/v1/subscriptions", headers: ["Authentication" : "Basic \(authString)"], query: ["customer" : user.stripe_id!, "plan" : box.plan_id!]).json()
        
        guard let subscription_id = json["id"]?.string else {
            throw Abort.custom(status: .internalServerError, message: json.string ?? "Unkown error.")
        }
        
        return subscription_id
    }
}

final class OrderCollection : RouteCollection, EmptyInitializable {
    
    init () {}
    
    typealias Wrapped = HTTP.Responder
    
    func build<Builder : RouteBuilder>(_ builder: Builder) where Builder.Value == Responder {
        
        builder.group("order") { order in
            
            order.post("customer", "add", String.self) { request, token in
                
                var user = try request.user()
                
                if user.stripe_id != nil {
                    _ = try Stripe.associate(paymentSource: token, withUser: user)
                    return try Response(status: .created, json: JSON(node: []))
                } else {
                    let id = try Stripe.createStripeCustomer(forUser: &user, withPaymentSource: token)
                    return try Response(status: .created, json: JSON(node: ["id" : id]))
                }
            }
            
            order.post("customer", "subscribe", Box.self) { request, box in
                
                if box.plan_id == nil {
                    try Stripe.createPlan(forBox: box)
                }
                
                let user = try request.user()
                let subscriptionId = try Stripe.createSubscription(forUser: user, forBox: box)
                
                var subscription = Subscription(withStripeSubscriptionId: subscriptionId, forBox: box, forUser: user)
                try subscription.save()
                
                return Response(status: .created)
            }
        }
    }
}
