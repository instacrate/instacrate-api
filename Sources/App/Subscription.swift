//
//  Subscription.swift
//  subber-api
//
//  Created by Hakon Hanesand on 9/27/16.
//
//

import Vapor
import Fluent

final class Subscription: Model, Preparation, NodeInitializable, NodeRepresentable, Entity {
    
    var id: Node?
    var exists = false
    
    let date: String
    let active: Bool
    
    var boxId: Node?
    
    init(node: Node, in context: Context) throws {
        id = try node.extract("id")
        date = try node.extract("date")
        active = try node.extract("active")
        boxId = try node.extract("boxId")
    }
    
    init(id: String? = nil, date: String, active: Bool, boxId: String) {
        self.id = id.flatMap { .string($0) }
        self.date = date
        self.active = active
        self.boxId = .string(boxId)
    }
    
    func makeNode(context: Context) throws -> Node {
        return try Node(node: [
            "id" : id!,
            "date" : .string(date),
            "active" : .bool(active),
            "boxId" : boxId!
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
        return try parent(boxId)
    }
}
