//
//  File.swift
//  subber-api
//
//  Created by Hakon Hanesand on 9/27/16.
//
//

import Vapor
import Fluent
import Auth
import Turnstile
import BCrypt

final class Customer: Model, Preparation, JSONConvertible, FastInitializable {
    
    static var requiredJSONFields = ["id", "email", "name", "password"]
    
    var id: Node?
    var exists = false
    
    let name: String
    let email: String
    let password: String
    let salt: BCryptSalt

    var defaultShipping: Node?
    var stripe_id: String?
    
    init(node: Node, in context: Context) throws {
        id = try? node.extract("id")
        defaultShipping = try? node.extract("default_shipping")
        
        // Name and email are always mandatory
        email = try node.extract("email")
        name = try node.extract("name")
        stripe_id = try? node.extract("stripe_id")
        
        let password = try node.extract("password") as String
         
        if let salt = try? node.extract("salt") as String {
            self.salt = try BCryptSalt(string: salt)
            self.password = password
        } else {
            self.salt = BCryptSalt()
            self.password = BCrypt.hash(password: password, salt: salt)
        }
    }
    
    func makeNode(context: Context) throws -> Node {
        return try Node(node: [
            "name" : .string(name),
            "email" : .string(email),
            "password" : .string(password),
            "salt" : .string(salt.string)
        ]).add(objects: ["stripe_id" : stripe_id,
                         "id" : id,
                         "default_shipping" : defaultShipping])
    }
    
    static func prepare(_ database: Database) throws {
        try database.create(self.entity) { box in
            box.id()
            box.string("name")
            box.string("stripe_id")
            box.string("email")
            box.string("password")
            box.string("salt")
            box.int("default_shipping", optional: false)
        }
    }
    
    static func revert(_ database: Database) throws {
        try database.delete(self.entity)
    }
}

extension Customer {
    
    func reviews() -> Children<Review> {
        return children("customer_id", Review.self)
    }

    func defaultShippingAddress() throws -> Parent<Shipping> {
        return try parent(defaultShipping)
    }
    
    func shippingAddresses() -> Children<Shipping> {
        return children("customer_id", Shipping.self)
    }
    
    func sessions() -> Children<Session> {
        return children("customer_id", Session.self)
    }
}

extension Customer: User {
    
    static func authenticate(credentials: Credentials) throws -> Auth.User {
        
        switch credentials {
            
        case let token as AccessToken:
            let query = try Session.query().filter("accessToken", token.string)
            
            guard let user = try query.first()?.user().first() else {
                throw AuthError.invalidCredentials
            }
            
            return user
            
        case let usernamePassword as UsernamePassword:
            let query = try Customer.query().filter("email", usernamePassword.username)
            
            guard let user = try query.first() else {
                throw AuthError.invalidCredentials
            }
            
            let hashedPassword = BCrypt.hash(password: usernamePassword.password, salt: user.salt)
            
            if user.password == hashedPassword {
                return user
            } else {
                throw AuthError.invalidBasicAuthorization
            }
            
        default:
            throw AuthError.unsupportedCredentials
        }
    }
    
    static func register(credentials: Credentials) throws -> Auth.User {
        throw Abort.custom(status: .badRequest, message: "Register not supported.")
    }
}

extension Customer: Relationable {
    
    typealias Relations = (reviews: [Review], shippings: [Shipping], sessions: [Session])

    func relations() throws -> (reviews: [Review], shippings: [Shipping], sessions: [Session]) {
        let reviews = try self.reviews().all()
        let shippingAddresess = try self.shippingAddresses().all()
        let sessions = try self.sessions().all()
        
        return (reviews, shippingAddresess, sessions)
    }
}
