//
//  Order.swift
//  subber-api
//
//  Created by Hakon Hanesand on 9/27/16.
//
//

import Vapor
import Fluent
import Foundation
import Stripe
import Sanitized

final class Order: Model, Preparation, JSONConvertible, Sanitizable {
    
    static var permitted: [String] = ["date", "fulfilled", "subscription_id", "shipping_id", "vendor_id", "box_id", "customer_id", "order_id"]
    
    var id: Node?
    var exists = false
    
    let date: Date
    let fulfilled: Bool
    
    var subscription_id: Node?
    var vendor_id: Node?
    var box_id: Node?
    var shipping_id: Node?
    var customer_id: Node?

    var order_id: String?

    init(with subscription_id: Node?, vendor_id: Node?, box_id: Node?, shipping_id: Node?, customer_id: Node?, order_id: String) {
        self.subscription_id = subscription_id
        self.vendor_id = vendor_id
        self.box_id = box_id
        self.shipping_id = shipping_id
        self.customer_id = customer_id
        self.order_id = order_id

        date = Date()
        fulfilled = false
    }
    
    init(node: Node, in context: Context) throws {
        id = try? node.extract("id")
        date = (try? node.extract("date")) ?? Date()
        fulfilled = (try? node.extract("fulfilled")) ?? false
        subscription_id = try node.extract("subscription_id")
        shipping_id = try node.extract("shipping_id")
        vendor_id = try node.extract("vendor_id")
        box_id = try node.extract("box_id")
        customer_id = try node.extract("customer_id")
    }

    func makeNode(context: Context) throws -> Node {
        return try Node(node: [
            "date" : .string(date.ISO8601String),
            "fulfilled" : .bool(fulfilled),
            "subscription_id" : subscription_id!,
            "shipping_id" : shipping_id!,
            "vendor_id" : vendor_id!,
            "box_id" : box_id!,
            "customer_id" : customer_id!
        ]).add(name: "id", node: id)
    }
    
    func postValidate() throws {
        guard (try? subscription().first()) ?? nil != nil else {
            throw ModelError.missingLink(from: Order.self, to: Subscription.self, id: subscription_id?.int)
        }
        
        guard (try? shippingAddress().first()) ?? nil != nil else {
            throw ModelError.missingLink(from: Order.self, to: Shipping.self, id: shipping_id?.int)
        }
        
        guard (try? vendor().first()) ?? nil != nil else {
            throw ModelError.missingLink(from: Order.self, to: Vendor.self, id: vendor_id?.int)
        }
        
        guard (try? box().first()) ?? nil != nil else {
            throw ModelError.missingLink(from: Order.self, to: Box.self, id: box_id?.int)
        }
        
        guard (try? customer().first()) ?? nil != nil else {
            throw ModelError.missingLink(from: Order.self, to: Customer.self, id: customer_id?.int)
        }
    }
    
    static func prepare(_ database: Database) throws {
        try database.create(self.entity, closure: { order in
            order.id()
            order.string("date")
            order.bool("fulfilled")
            order.parent(Customer.self, optional: false)
            order.parent(Box.self, optional: false)
            order.parent(Subscription.self, optional: false)
            order.parent(Shipping.self, optional: false)
            order.parent(Vendor.self, optional: false)
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
    
    func vendor() throws -> Parent<Vendor> {
        return try parent(vendor_id)
    }

    func box() throws -> Parent<Box> {
        return try parent(box_id)
    }

    func customer() throws -> Parent<Customer> {
        return try parent(customer_id)
    }
}

extension Order: Relationable {

    typealias Relations = (subscription: Subscription, shipping: Shipping)

    func relations() throws -> (subscription: Subscription, shipping: Shipping) {
        guard let sub = try subscription().get() else {
            throw Abort.custom(status: .internalServerError, message: "Missing subscription for order with id \(id) on date \(date)")
        }
        
        guard let ship = try shippingAddress().get() else {
            throw Abort.custom(status: .internalServerError, message: "Missing shipping id for order with id \(id) on date \(date)")
        }
        
        return (sub, ship)
    }
}

extension Order {
    
    
}
