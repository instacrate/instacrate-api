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
    
    var user_id: Node?
    
    init(node: Node, in context: Context) throws {
        id = try node.extract("id")
        address = try node.extract("address")
        user_id = try node.extract("user_id")
    }
    
    init(id: String? = nil, address: String, user_id: String) {
        self.id = id.flatMap { .string($0) }
        self.address = address
        self.user_id = .string(user_id)
    }
    
    func makeNode(context: Context) throws -> Node {
        return try Node(node: [
            "id" : id!,
            "address" : .string(address),
            "user_id" : user_id!
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
        return try parent(user_id)
    }
}
