//
//  UserSession.swift
//  subber-api
//
//  Created by Hakon Hanesand on 9/28/16.
//
//

import Vapor
import Fluent
import Auth

enum SessionType: String, NodeRepresentable {
    case user = "user"
    case vendor = "vendor"
    
    func makeNode(context: Context = EmptyNode) throws -> Node {
        return .string(self.rawValue)
    }
}

extension AccessToken: NodeRepresentable {
    
    public func makeNode(context: Context = EmptyNode) throws -> Node {
        return .string(self.string)
    }
}

final class Session: Model, Preparation, JSONConvertible {
    
    var id: Node?
    var exists = false
    
    let accessToken: String
    let type: SessionType
    
    var customer_id: Node?
    
    init(node: Node, in context: Context) throws {
        id = try node.extract("id")
        accessToken = try node.extract("accessToken")
        customer_id = try node.extract("customer_id")
        
        type = try node.extract("type") { (_type: String) in
            return SessionType(rawValue: _type)
        }!
    }
    
    init(id: String? = nil, token: String, subject_id: String, type: SessionType) {
        self.id = id.flatMap { .string($0) }
        self.accessToken = token
        self.customer_id = .string(subject_id)
        self.type = type
    }
    
    func makeNode(context: Context) throws -> Node {
        return try Node(node: [
            "accessToken" : .string(accessToken),
            "customer_id" : customer_id!,
            "type" : .string(type.rawValue)
        ]).add(name: "id", node: id)
    }
    
    static func prepare(_ database: Database) throws {
        try database.create(self.entity, closure: { vendor in
            vendor.id()
            vendor.string("accessToken")
            vendor.string("type")
            vendor.parent(Customer.self, optional: false)
        })
    }
    
    static func revert(_ database: Database) throws {
        try database.delete(self.entity)
    }
}

extension Session {
    
    func user() throws -> Parent<Customer> {
        precondition(self.type == .user)
        return try parent(customer_id)
    }
    
    func vendor() throws -> Parent<Vendor> {
        precondition(self.type == .vendor)
        return try parent(customer_id)
    }
    
    static func session(forToken token: AccessToken, type: SessionType) throws -> Session {
        let query = try Session.query().filter("accessToken", token).filter("type", type)
        
        guard let session = try query.first() else {
            throw AuthError.invalidCredentials
        }
        
        return session
    }
}

extension Session: Relationable {
    
    typealias Relations = User

    func relations() throws -> User {
        guard let user = try user().get() else {
            throw Abort.custom(status: .internalServerError, message: "Missing user relation for session with id \(id)")
        }
        
        return user
    }
}
