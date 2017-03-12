//
//  Subscription.swift
//  subber-api
//
//  Created by Hakon Hanesand on 9/27/16.
//
//

import Vapor
import Fluent
import Foundation
import Sanitized

enum Frequency: String, StringInitializable {
    case once
    case monthly
    
    init?(from string: String) throws {
        guard let frequency = Frequency.init(rawValue: string) else {
            throw Abort.custom(status: .badRequest, message: "Invalid value for frequency. Can be once or monthly.")
        }
        
        self = frequency
    }
}

final class Subscription: Model, Preparation, JSONConvertible, Sanitizable {
    
    static var permitted: [String] = ["date", "active", "frequency", "box_id", "shipping_id", "payment"]
    
    var id: Node?
    var exists = false
    
    let date: Date
    let active: Bool
    let frequency: Frequency
    
    var box_id: Node?
    var shipping_id: Node?
    var customer_id: Node?
    var vendor_id: Node?
    var coupon_id: Node?
    var payment: String
    
    var sub_id: String?
    
    init(node: Node, in context: Context) throws {
        id = try? node.extract("id")
        
        date = (try? node.extract("date")) ?? Date()
        active = (try? node.extract("active")) ?? true
        
        frequency = try node.extract("frequency") { (freq: String) in
            return Frequency.init(rawValue: freq)
        } ?? .monthly
        
        box_id = try node.extract("box_id")
        shipping_id = try node.extract("shipping_id")
        customer_id = try node.extract("customer_id")
        payment = try node.extract("payment")
        coupon_id = try node.extract("coupon_id")
        
        sub_id = try? node.extract("sub_id")
    }
    
    func makeNode(context: Context) throws -> Node {
        return try Node(node: [
            "date" : .string(date.ISO8601String),
            "active" : .bool(active),
            "box_id" : box_id!,
            "shipping_id" : shipping_id!,
            "customer_id" : customer_id!,
            "frequency" : .string(frequency.rawValue),
            "payment" : .string(payment)
        ]).add(objects: [
            "id" : id,
            "sub_id" : sub_id,
            "coupon_id" : coupon_id
        ])
    }
    
    func postValidate() throws {

        guard let address = (try? self.address().first()) ?? nil else {
            throw ModelError.missingLink(from: Subscription.self, to: Shipping.self, id: shipping_id?.int)
        }
        
        guard address.customer_id == customer_id else {
            throw ModelError.ownerMismatch(from: Subscription.self, to: Shipping.self, fromId: customer_id?.int, toId: address.customer_id?.int)
        }
        
        guard (try? box().first()) ?? nil != nil else {
            throw ModelError.missingLink(from: Subscription.self, to: Box.self, id: box_id?.int)
        }
        
        guard (try? customer().first()) ?? nil != nil else {
            throw ModelError.missingLink(from: Subscription.self, to: Customer.self, id: customer_id?.int)
        }
    }
    
    static func prepare(_ database: Database) throws {
        try database.create(self.entity, closure: { subscription in
            subscription.id()
            subscription.string("date")
            subscription.bool("active")
            subscription.string("sub_id")
            subscription.string("frequency")
            subscription.string("payment")
            subscription.parent(Box.self, optional: false)
            subscription.parent(Shipping.self, optional: false)
            subscription.parent(Customer.self, optional: false)
            subscription.parent(Coupon.self, optional: true)
        })
    }
    
    static func revert(_ database: Database) throws {
        try database.delete(self.entity)
    }
}

extension Subscription {
    
    func orders() -> Children<Order> {
        return fix_children()
    }
    
    func address() throws -> Parent<Shipping> {
        return try parent(shipping_id)
    }
    
    func box() throws -> Parent<Box> {
        return try parent(box_id)
    }
    
    func customer() throws -> Parent<Customer> {
        return try parent(customer_id)
    }
    
    func coupon() throws -> Parent<Coupon> {
        return try parent(coupon_id)
    }
}

extension Subscription: Relationable {

    typealias Relations = (orders: [Order], address: Shipping, box: Box)
    
    func relations() throws -> (orders: [Order], address: Shipping, box: Box) {
        let orders = try self.orders().all()
        
        guard let shipping = try self.address().get() else {
            throw Abort.custom(status: .internalServerError, message: "Missing box relation for subscription with id \(String(describing: id))")
        }
        
        guard let box = try self.box().get() else {
            throw Abort.custom(status: .internalServerError, message: "Missing box relation for subscription with id \(String(describing: id))")
        }
        
        return (orders, shipping, box)
    }
}
