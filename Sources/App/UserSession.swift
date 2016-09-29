//
//  UserSession.swift
//  subber-api
//
//  Created by Hakon Hanesand on 9/28/16.
//
//

import Vapor
import Fluent

final class UserSession: Model, Preparation, NodeInitializable, NodeRepresentable, Entity {
    
    var id: Node?
    var exists = false
    
    let accessToken: String
    
    var userId: Node?
    
    init(node: Node, in context: Context) throws {
        id = try node.extract("id")
        accessToken = try node.extract("accessToken")
        userId = try node.extract("userId")
    }
    
    init(id: String? = nil, accessToken: String, userId: String) {
        self.id = id.flatMap { .string($0) }
        self.accessToken = accessToken
        self.userId = .string(userId)
    }
    
    func makeNode(context: Context) throws -> Node {
        return try Node(node: [
            "id" : id!,
            "accessToken" : .string(accessToken),
            "userId" : userId!
            ])
    }
    
    static func prepare(_ database: Database) throws {
        try database.create(self.entity, closure: { vendor in
            vendor.id()
            vendor.string("url")
            vendor.parent(User.self, optional: false)
        })
    }
    
    static func revert(_ database: Database) throws {
        try database.delete(self.entity)
    }
}

extension UserSession {
    
    func user() throws -> Parent<User> {
        return try parent(userId)
    }
}
