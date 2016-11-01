//
//  Subscription.swift
//  subber-api
//
//  Created by Hakon Hanesand on 9/27/16.
//
//

import Vapor
import Fluent

final class Subscription: Model, Preparation, JSONConvertible {
    
    var id: Node?
    var exists = false
    
    let date: String
    let active: Bool
    
    var box_id: Node?
    var shipping_id: Node?
    
    init(node: Node, in context: Context) throws {
        id = try node.extract("id")
        date = try node.extract("date")
        active = try node.extract("active")
        box_id = try node.extract("box_id")
        shipping_id = try node.extract("shipping_id")
    }
    
    init(id: String? = nil, date: String, active: Bool, box_id: String) {
        self.id = id.flatMap { .string($0) }
        self.date = date
        self.active = active
        self.box_id = .string(box_id)
    }
    
    func makeNode(context: Context) throws -> Node {
        return try Node(node: [
            "date" : .string(date),
            "active" : .bool(active),
            "box_id" : box_id!
        ])
    }
    
    static func prepare(_ database: Database) throws {
        try database.create(self.entity, closure: { subscription in
            subscription.id()
            subscription.string("date")
            subscription.bool("active")
            subscription.parent(Box.self, optional: false)
            subscription.parent(Shipping.self, optional: false)
        })
    }
    
    static func revert(_ database: Database) throws {
        try database.delete(self.entity)
    }
}

extension Subscription {
    
    func orders() -> Children<Order> {
        return children()
    }
    
    func address() throws -> Parent<Shipping> {
        return try parent(shipping_id)
    }
    
    func box() throws -> Parent<Box> {
        return try parent(box_id)
    }
}

extension Subscription: Relationable {

    typealias Relations = (orders: [Order], address: Shipping, box: Box)
    
    func relations() throws -> (orders: [Order], address: Shipping, box: Box) {
        let orders = try self.orders().all()
        
        guard let shipping = try self.address().get() else {
            throw Abort.custom(status: .internalServerError, message: "Missing box relation for subscription with id \(id)")
        }
        
        guard let box = try self.box().get() else {
            throw Abort.custom(status: .internalServerError, message: "Missing box relation for subscription with id \(id)")
        }
        
        return (orders, shipping, box)
    }
}
