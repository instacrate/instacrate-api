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

final class User: Model, Preparation, JSONConvertible, FastInitializable {
    
    static var requiredJSONFields = ["id", "email", "name", "password"]
    
    var id: Node?
    var exists = false
    
    let name: String
    let email: String
    let password: String
    let salt: BCryptSalt
    
    let stripe_id: String?
    
    init(node: Node, in context: Context) throws {
        id = try? node.extract("id")
        
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
            self.password = User.hashed(password: password, salt: salt)
        }
    }
    
    func makeNode(context: Context) throws -> Node {
        return try Node(node: [
            "name" : .string(name),
            "email" : .string(email),
            "password" : .string(password),
            "salt" : .string(salt.string)
            ]).add(objects: ["stripe_id" : self.stripe_id,
                             "id" : self.id])
    }
    
    static func prepare(_ database: Database) throws {
        try database.create(self.entity, closure: { box in
            box.id()
            box.string("name")
            box.string("stripe_id")
            box.string("email")
            box.string("password")
            box.string("salt")
        })
    }
    
    static func revert(_ database: Database) throws {
        try database.delete(self.entity)
    }
    
    static func hashed(password: String, salt: BCryptSalt) -> String {
        return BCrypt.hash(password: password, salt: salt)
    }
    
    func createStripeID() throws -> String {
        guard let authString = "sk_test_6zSrUMIQfOCUorVvFMS2LEzn:".data(using: .utf8)?.base64EncodedString() else {
            throw Abort.custom(status: .internalServerError, message: "Failed to encode secret key.")
        }
        return ""
//        drop.client.post("https://api.stripe.com/v1/customers", headers: ["Authentication" : "Basic \(authString)"], query: ["source" : "tok_19DMWqDIUJ4Quxdky9tpcvyS"], body: <#T##BodyRepresentable#>)
    }
}

extension User {
    
    func reviews() -> Children<Review> {
        return children("user_id", Review.self)
    }
    
    func shippingAddresses() -> Children<Shipping> {
        return children("user_id", Shipping.self)
    }
    
    func sessions() -> Children<Session> {
        return children("user_id", Session.self)
    }
}

extension User: Auth.User {
    
    static func authenticate(credentials: Credentials) throws -> Auth.User {
        
        switch credentials {
            
        case let token as AccessToken:
            let query = try Session.query().filter("accessToken", token.string)
            
            guard let user = try query.first()?.user().first() else {
                throw AuthError.invalidCredentials
            }
            
            return user
            
        case let usernamePassword as UsernamePassword:
            let query = try User.query().filter("email", usernamePassword.username)
            
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

import HTTP

extension Request {
    
    func user() throws -> User {
        guard let user = try auth.user() as? User else {
            throw Abort.custom(status: .badRequest, message: "Invalid user type.")
        }
        
        return user
    }
}

extension User: Relationable {
    
    typealias Relations = (reviews: [Review], shippings: [Shipping], sessions: [Session])

    func relations() throws -> (reviews: [Review], shippings: [Shipping], sessions: [Session]) {
        let reviews = try self.reviews().all()
        let shippingAddresess = try self.shippingAddresses().all()
        let sessions = try self.sessions().all()
        
        return (reviews, shippingAddresess, sessions)
    }
}
