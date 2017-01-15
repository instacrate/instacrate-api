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

final class Order: Model, Preparation, JSONConvertible, FastInitializable {
    
    static var requiredJSONFields = ["fulfilled", "subscription_id", "shipping_id", "vendor_id"]
    
    var id: Node?
    var exists = false
    
    let date: Date
    let fulfilled: Bool
    
    var subscription_id: Node?
    var vendor_id: Node?
    var box_id: Node?
    var shipping_id: Node?
    var customer_id: Node?
    
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
