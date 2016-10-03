//
//  Order.swift
//  subber-api
//
//  Created by Hakon Hanesand on 9/27/16.
//
//

import Vapor
import Fluent

final class Order: Model, Preparation, NodeInitializable, NodeRepresentable, Entity {
    
    var id: Node?
    var exists = false
    
    let date: String
    let fulfilled: Bool
    
    var subscription_id: Node?
    var shipping_id: Node?
    
    init(node: Node, in context: Context) throws {
        id = try node.extract("id")
        date = try node.extract("url")
        fulfilled = try node.extract("fulfilled")
        subscription_id = try node.extract("subscription_id")
        shipping_id = try node.extract("shipping_id")
    }
    
    init(id: String? = nil, date: String, fulfilled: Bool, subscription_id: Node, shipping_id: Node) {
        self.id = id.flatMap { .string($0) }
        self.date = date
        self.fulfilled = fulfilled
        self.subscription_id = subscription_id
        self.shipping_id = shipping_id
    }
    
    convenience init(subscription: Subscription, shipping: Shipping) {
        precondition(shipping.id != nil, "Shipping model does not have an id, save to database first?")
        precondition(subscription.id != nil, "Subscription model does not have an id, save to database first?")
        
        // TODO : Dates
        self.init(date: "", fulfilled: false, subscription_id: subscription.id!, shipping_id: shipping.id!)
    }
    
    func makeNode(context: Context) throws -> Node {
        return try Node(node: [
            "id" : id!,
            "date" : .string(date),
            "fulfilled" : .bool(fulfilled),
            "subscription_id" : subscription_id!,
            "shipping_id" : shipping_id!
        ])
    }
    
    static func prepare(_ database: Database) throws {
        try database.create(self.entity, closure: { order in
            order.id()
            order.string("date")
            order.bool("fulfilled")
            order.parent(Subscription.self, optional: false)
            order.parent(Shipping.self, optional: false)
        })
    }
    
    static func revert(_ database: Database) throws {
        try database.delete(self.entity)
    }
}

extension Order {
    
    func subscription() throws -> Parent<Subscription> {
        return try parent(subscription_id)
    }
    
    func shippingAddress() throws -> Parent<Shipping> {
        return try parent(shipping_id)
    }
}
