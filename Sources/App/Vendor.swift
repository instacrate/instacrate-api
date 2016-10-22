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

final class Vendor: Model, Preparation, JSONConvertible {
    
    var id: Node?
    var exists = false

    let contactName: String
    let contactPhone: String
    let contactEmail: String
    
    let publicWebsite: String
    let supportEmail: String
    let businessName: String
    
    let parentCompanyName: String
    let established: Date
    
    var category_id: Node?
    let estimatedTotalSubscribers: Int
    
    let dateCreated: Date

    let username: String
    let password: String
    
    let cut: Double
    
    init(node: Node, in context: Context) throws {
        
        id = try? node.extract("id")
        
        contactName = try node.extract("contactName")
        businessName = try node.extract("business")
        parentCompanyName = try node.extract("parentCompanyName")
        
        contactPhone = try node.extract("phone")
        contactEmail = try node.extract("contactEmail")
        supportEmail = try node.extract("publicEmail")
        publicWebsite = try node.extract("website")
        
        cut = try node.extract("cut")
        estimatedTotalSubscribers = try node.extract("estimatedTotalSubscribers")
        
        established = try node.extract("established") { Date(timeIntervalSince1970: $0) }
        dateCreated = try node.extract("dateCreated") { Date(timeIntervalSince1970: $0) }
        
        username = try node.extract("username")
        password = try node.extract("password")
    }
    
    func makeNode(context: Context) throws -> Node {
        return try Node(node: [
            
            "contactName" : .string(contactName),
            "businessName" : .string(businessName),
            "parentCompanyName" : .string(parentCompanyName),
            
            "contactPhone" : .string(contactPhone),
            "contactEmail" : .string(contactEmail),
            "supportEmail" : .string(supportEmail),
            "publicWebsite" : .string(publicWebsite),
            
            "cut" : .number(.double(cut)),
            "estimatedTotalSubscribers" : .number(.int(estimatedTotalSubscribers)),
            
            "established" : .number(.double(established.timeIntervalSince1970)),
            "dateCreated" : .number(.double(dateCreated.timeIntervalSince1970)),
            
            "username" : .string(username),
            "password" : .string(password),
        ]).add(objects: ["id" : id,
                         "category" : category_id])
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
            vendor.double("established")
            vendor.double("dateCreated")
            vendor.string("username")
            vendor.string("password")
        })
    }
    
    static func revert(_ database: Database) throws {
        try database.delete(self.entity)
    }
}

extension Vendor {
    
    func boxes() -> Children<Box> {
        return children("vendor_id", Box.self)
    }
    
    func category() throws -> Parent<Category> {
        return try parent(category_id)
    }
}

extension Vendor: Relationable {
    
    typealias boxNode = AnyRelationNode<Vendor, Box, Many>
    typealias categoryNode = AnyRelationNode<Vendor, Category, One>
    
    func queryForRelation<R: Relation>(relation: R.Type) throws -> Query<R.Target> {
        switch R.self {
        case is boxNode.Rel.Type:
            return try children().makeQuery()
        default:
            throw Abort.custom(status: .internalServerError, message: "No such relation for box")
        }
    }
    
    func relations(forFormat format: Format) throws -> [Box] {
        return try boxNode.run(onModel: self, forFormat: format)
    }

}
