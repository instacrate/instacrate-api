//
//  UserSession.swift
//  subber-api
//
//  Created by Hakon Hanesand on 9/28/16.
//
//

import Vapor
import Fluent

final class Session: Model, Preparation, JSONConvertible {
    
    var id: Node?
    var exists = false
    
    let accessToken: String
    
    var user_id: Node?
    
    init(node: Node, in context: Context) throws {
        id = try node.extract("id")
        accessToken = try node.extract("accessToken")
        user_id = try node.extract("user_id")
    }
    
    init(id: String? = nil, accessToken: String, user_id: String) {
        self.id = id.flatMap { .string($0) }
        self.accessToken = accessToken
        self.user_id = .string(user_id)
    }
    
    func makeNode(context: Context) throws -> Node {
        return try Node(node: [
            "id" : id!,
            "accessToken" : .string(accessToken),
            "user_id" : user_id!
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

extension Session {
    
    func user() throws -> Parent<User> {
        return try parent(user_id)
    }
}
