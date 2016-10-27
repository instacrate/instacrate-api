//
//  Vendor.swift
//  subber-api
//
//  Created by Hakon Hanesand on 9/27/16.
//
//

import Vapor
import Fluent
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

enum ApplicationState: Int {
    
    case none = 0
    case recieved
    case rejected
    case accepted
}

final class Vendor: Model, Preparation, JSONConvertible {
    
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
    
    let cut: Double?
    
    init(node: Node, in context: Context) throws {
        
        id = try? node.extract("id")
        
        applicationState = try node.extract("applicationState") { (value: Int) in
            return ApplicationState(rawValue: value)
        } ?? .none
        
        contactName = try node.extract("contactName")
        businessName = try node.extract("businessName")
        parentCompanyName = try node.extract("parentCompanyName")
        
        contactPhone = try node.extract("contactPhone")
        contactEmail = try node.extract("contactEmail")
        supportEmail = try node.extract("supportEmail")
        publicWebsite = try node.extract("publicWebsite")
        
        established = try node.extract("established")
        dateCreated = try node.extract("dateCreated") { Date(timeIntervalSince1970: $0) }
        
        estimatedTotalSubscribers = try node.extract("estimatedTotalSubscribers")
        
        category_id = try node.autoextract(type: Category.self, key: "category")
        
        cut = try? node.extract("cut")
    }
    
    func makeNode(context: Context) throws -> Node {
        return try Node(node: [
            "contactName" : .string(contactName),
            "businessName" : .string(businessName),
            "parentCompanyName" : .string(parentCompanyName),
            "applicationState" : .number(.int(applicationState.rawValue)),
            
            "contactPhone" : .string(contactPhone),
            "contactEmail" : .string(contactEmail),
            "supportEmail" : .string(supportEmail),
            "publicWebsite" : .string(publicWebsite),
            "estimatedTotalSubscribers" : .number(.int(estimatedTotalSubscribers)),
            
            "established" : .string(established),
            "dateCreated" : .number(.double(dateCreated.timeIntervalSince1970)),
        ]).add(objects: ["id" : id,
                         "category_id" : category_id,
                         "cut" : cut,
                         "username" : username,
                         "password": password])
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
            vendor.double("dateCreated")
            vendor.string("username")
            vendor.double("applicationState")
            vendor.string("password")
            vendor.id("category_id")
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
        
        guard let state = try? node.extract("applicationState") as Int else {
            throw Abort.custom(status: .badRequest, message: "Missing application state in json body.")
        }
        
        self.applicationState = ApplicationState(rawValue: state) ?? .none
        
        if self.applicationState == .accepted {
            username = try node.extract("username")
            password = try node.extract("password")
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
