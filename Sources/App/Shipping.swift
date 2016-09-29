//
//  Shipping.swift
//  subber-api
//
//  Created by Hakon Hanesand on 9/27/16.
//
//

import Vapor
import Fluent

final class Shipping: Model, Preparation, NodeInitializable, NodeRepresentable, Entity {
    
    var id: Node?
    var exists = false
    
    let address: String
    
    var userId: Node?
    
    init(node: Node, in context: Context) throws {
        id = try node.extract("id")
        address = try node.extract("address")
        userId = try node.extract("userId")
    }
    
    init(id: String? = nil, address: String, userId: String) {
        self.id = id.flatMap { .string($0) }
        self.address = address
        self.userId = .string(userId)
    }
    
    func makeNode(context: Context) throws -> Node {
        return try Node(node: [
            "id" : id!,
            "address" : .string(address),
            "userId" : userId!
        ])
    }
    
    static func prepare(_ database: Database) throws {
        try database.create(self.entity, closure: { shipping in
            shipping.id()
            shipping.string("address")
            shipping.parent(User.self, optional: false)
        })
    }
    
    static func revert(_ database: Database) throws {
        try database.delete(self.entity)
    }
}

extension Shipping {
    
    func orders() -> Children<Order> {
        return children()
    }
    
    func user() throws -> Parent<User> {
        return try parent(userId)
    }
}
