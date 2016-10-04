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
    
    init(node: Node, in context: Context) throws {
        id = try node.extract("id")
        date = try node.extract("date")
        active = try node.extract("active")
        box_id = try node.extract("box_id")
    }
    
    init(id: String? = nil, date: String, active: Bool, box_id: String) {
        self.id = id.flatMap { .string($0) }
        self.date = date
        self.active = active
        self.box_id = .string(box_id)
    }
    
    func makeNode(context: Context) throws -> Node {
        return try Node(node: [
            "id" : id!,
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
    
    func defaultShippingAddress() -> Children<Shipping> {
        return children()
    }
    
    func box() throws -> Parent<Box> {
        return try parent(box_id)
    }
}
