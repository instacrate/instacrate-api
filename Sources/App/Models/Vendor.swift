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
        } else if let object_id = try? self.extract("\(key)_id") as String {
            return .string(object_id)
        }
        
        return nil
    }
}

protocol Updateable: Model {
    
    func update(withJSON json: JSON) throws
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

    var username: String?
    var password: String?
    var salt: BCryptSalt?
    
    let cut: Double?
    
    init(node: Node, in context: Context) throws {
        
        id = try? node.extract("id")
        
        applicationState = try node.extract("applicationState")
        
        if applicationState == .accepted {
            username = try node.extract("username")
            password = try node.extract("password")
            salt = try node.extract("salt")
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
        
        cut = try? node.extract("cut")
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
        ]).add(objects: ["id" : id,
                         "category_id" : category_id,
                         "cut" : cut,
                         "username" : username,
                         "password": password,
                         "salt" : salt?.string])
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

extension Vendor: Updateable {
    
    func update(withJSON json: JSON) throws {
        let node = json.makeNode()
    
        guard let state: ApplicationState = try node.extract("applicationState") else {
            throw Abort.custom(status: .badRequest, message: "Missing application state in json body.")
        }
        
        self.applicationState = state
        
        if self.applicationState == .accepted {
            username = try node.extract("username")
            salt = BCryptSalt()
            
            let plainTextPassword = try node.extract("password") as String
            password = BCrypt.hash(password: plainTextPassword, salt: salt!)
        }
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
            
            guard let salt = vendor.salt else {
                throw Abort.custom(status: .internalServerError, message: "Missing salt for vendor with id \(vendor.id!)")
            }
            
            if BCrypt.hash(password: usernamePassword.password, salt: salt) == vendor.password {
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
