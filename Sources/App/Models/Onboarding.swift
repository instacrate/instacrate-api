//
//  Onboarding.swift
//  subber-api
//
//  Created by Hakon Hanesand on 1/22/17.
//
//

import Foundation
import Vapor
import Auth
import Fluent
import Sanitized

final class Onboarding: Model, JSONConvertible, Preparation, Sanitizable {
    
    static var permitted: [String] = ["email"]
    
    var id: Node?
    var exists = false
    
    let email: String
    
    init(node: Node, in context: Context = EmptyNode) throws {
        id = try node.extract("id")
        email = try node.extract("email")
    }
    
    func makeNode(context: Context = EmptyNode) throws -> Node {
        return try Node(node: [
            "email" : .string(email)
        ]).add(objects: [
            "id" : id
        ])
    }
    
    static func prepare(_ database: Database) throws {
        try database.create(self.entity) { onboarding in
            onboarding.string("email")
            onboarding.id()
        }
    }
    
    static func revert(_ database: Database) throws {
        try database.delete(self.entity)
    }
}
