//
//  Vendor.swift
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
import Foundation

extension Node {

    func autoextract<T: Model>(type: T.Type, key: String) throws -> Node? {

        if var object = try? self.extract(key) as T {
            try object.save()
            return object.id
        }

        guard let object_id: String = try self.extract("\(key)_id") else {
            throw Abort.custom(status: .badRequest, message: "Missing value for \(key) or \(key)_id")
        }
        
        return .string(object_id)
    }
}

enum ApplicationState: String, NodeConvertible {
    
    case none = "none"
    case recieved = "recieved"
    case rejected = "rejected"
    case accepted = "accepted"
    
    init(node: Node, in context: Context) throws {
        
        guard let state = node.string.flatMap ({ ApplicationState(rawValue: $0) }) else {
            throw Abort.custom(status: .badRequest, message: "Invalid value for application state.")
        }
        
        self = state
    }
    
    func makeNode(context: Context = EmptyNode) throws -> Node {
        return .string(rawValue)
    }
}

extension BCryptSalt: NodeInitializable {
    
    public init(node: Node, in context: Context) throws {
        guard let salt = try node.string.flatMap ({ try BCryptSalt(string: $0) }) else {
            throw Abort.custom(status: .badRequest, message: "Invalid salt.")
        }
        
        self = salt
    }
}

final class Vendor: Model, Preparation, JSONConvertible, FastInitializable {
    
    static var requiredJSONFields = ["contactName", "businessName", "parentCompanyName", "contactPhone", "contactEmail", "supportEmail", "publicWebsite", "dateCreated", "established", "category_id or category", "estimatedTotalSubscribers"]
    
    var id: Node?
    var exists = false

    let contactName: String
    let contactPhone: String
    let contactEmail: String
    var applicationState: ApplicationState = .none
    
    let publicWebsite: String
    let supportEmail: String
    let businessName: String
    
    let parentCompanyName: String
    let established: String
    
    var category_id: Node?
    let estimatedTotalSubscribers: Int
    
    let dateCreated: Date

    var username: String
    var password: String
    var salt: BCryptSalt

    var stripeAccountId: String?
    
    let cut: Double?
    
    init(node: Node, in context: Context) throws {
        
        id = try? node.extract("id")
        
        applicationState = try node.extract("applicationState")
        
        username = try node.extract("username")
        let password = try node.extract("password") as String
        
        if let salt = try? node.extract("salt") as String {
            self.salt = try BCryptSalt(string: salt)
            self.password = password
        } else {
            self.salt = BCryptSalt()
            self.password = BCrypt.hash(password: password, salt: salt)
        }
        
        contactName = try node.extract("contactName")
        businessName = try node.extract("businessName")
        parentCompanyName = try node.extract("parentCompanyName")
        
        contactPhone = try node.extract("contactPhone")
        contactEmail = try node.extract("contactEmail")
        supportEmail = try node.extract("supportEmail")
        publicWebsite = try node.extract("publicWebsite")
        
        established = try node.extract("established")
        dateCreated = (try? node.extract("dateCreated")) ?? Date()
        
        estimatedTotalSubscribers = try node.extract("estimatedTotalSubscribers")
        
        category_id = try node.autoextract(type: Category.self, key: "category")
        
        cut = (try? node.extract("cut")) ?? 0.08
        stripeAccountId = try? node.extract("stripeAccountId")
    }
    
    func makeNode(context: Context) throws -> Node {
        return try Node(node: [
            "contactName" : .string(contactName),
            "businessName" : .string(businessName),
            "parentCompanyName" : .string(parentCompanyName),
            "applicationState" : applicationState.makeNode(),
            
            "contactPhone" : .string(contactPhone),
            "contactEmail" : .string(contactEmail),
            "supportEmail" : .string(supportEmail),
            "publicWebsite" : .string(publicWebsite),
            "estimatedTotalSubscribers" : .number(.int(estimatedTotalSubscribers)),
            
            "established" : .string(established),
            "dateCreated" : .string(dateCreated.ISO8601String),
            
            "username" : .string(username),
            "password": .string(password),
            "salt" : .string(salt.string)
        ]).add(objects: ["id" : id,
                         "category_id" : category_id,
                         "cut" : cut])
    }
    
    static func prepare(_ database: Database) throws {
        try database.create(self.entity, closure: { vendor in
            vendor.id()
            vendor.string("contactName")
            vendor.string("businessName")
            vendor.string("parentCompanyName")
            vendor.string("contactPhone")
            vendor.string("contactEmail")
            vendor.double("supportEmail")
            vendor.string("publicWebsite")
            vendor.double("cut")
            vendor.string("estimatedTotalSubscribers")
            vendor.string("established")
            vendor.string("dateCreated")
            vendor.string("username")
            vendor.string("password")
            vendor.string("salt")
            vendor.double("applicationState")
            vendor.parent(Category.self, optional: false)
        })
    }
    
    static func revert(_ database: Database) throws {
        try database.delete(self.entity)
    }
}

extension Vendor {
    
    func boxes() -> Children<Box> {
        return children()
    }
    
    func category() throws -> Parent<Category> {
        return try parent(category_id)
    }
}

extension Vendor: Relationable {

    typealias Relations = (boxes: [Box], category: Category)
    
    func relations() throws -> (boxes: [Box], category: Category) {
        let boxes = try self.boxes().all()
        
        guard let category = try self.category().get() else {
            throw Abort.custom(status: .internalServerError, message: "Missing category relation for vendor with name \(username)")
        }
        
        return (boxes, category)
    }
}

extension Vendor: User {
    
    static func authenticate(credentials: Credentials) throws -> Auth.User {
        
        switch credentials {
            
        case let token as AccessToken:
            let session = try Session.session(forToken: token, type: .vendor)
            
            guard let vendor = try session.vendor().get() else {
                throw AuthError.invalidCredentials
            }
            
            return vendor
            
        case let usernamePassword as UsernamePassword:
            let query = try Vendor.query().filter("username", usernamePassword.username).filter("applicationState", ApplicationState.accepted)
            
            guard let vendor = try query.first() else {
                throw AuthError.invalidCredentials
            }
            
            if vendor.password == BCrypt.hash(password: usernamePassword.password, salt: vendor.salt) {
                return vendor
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
