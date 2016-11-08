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

final class OrderCollection : RouteCollection, EmptyInitializable {
    
    init () {}
    
    typealias Wrapped = HTTP.Responder
    
    func build<Builder : RouteBuilder>(_ builder: Builder) where Builder.Value == Responder {
        
        builder.group("order") { order in
            
            order.post(Subscription.self, Shipping.self) { request, subscription, shipping in
                
                let user = try request.user()
                let stripe_id = try user.stripe_id ?? user.createStripeID()
                
                var order = Order(subscription: subscription, shipping: shipping)
                try? order.save()
                
                guard order.id != nil else {
                    throw Abort.custom(status: .internalServerError, message: "Error saving new order to database")
                }
                
                return try! order.makeJSON()
            }
        }
    }
}
