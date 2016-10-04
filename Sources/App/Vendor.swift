//
//  Vendor.swift
//  subber-api
//
//  Created by Hakon Hanesand on 9/27/16.
//
//

import Vapor
import Fluent

final class Vendor: Model, Preparation, JSONConvertible {
    
    var id: Node?
    var exists = false
    
    let name: String
    let description: String
    let website: String
    let email: String
    let username: String
    let cut: Double
    let contactEmail: String
    let contactName: String
    let password: String
    
    init(node: Node, in context: Context) throws {
        id = try node.extract("id")
        name = try node.extract("name")
        description = try node.extract("description")
        website = try node.extract("website")
        email = try node.extract("email")
        username = try node.extract("username")
        cut = try node.extract("cut")
        contactEmail = try node.extract("contactEmail")
        contactName = try node.extract("contactName")
        password = try node.extract("password")
    }
    
    init(id: String? = nil, name: String, description: String, website: String, email: String, username: String, cut: Double, contactEmail: String, contactName: String, password: String) {
        self.id = id.flatMap { .string($0) }
        self.name = name
        self.description = description
        self.website = website
        self.email = email
        self.username = username
        self.cut = cut
        self.contactEmail = contactEmail
        self.contactName = contactName
        self.password = password
    }
    
    func makeNode(context: Context) throws -> Node {
        return try Node(node: [
            "id" : id!,
            "name" : .string(name),
            "description" : .string(description),
            "website" : .string(website),
            "email" : .string(email),
            "username" : .string(username),
            "cut" : .number(.double(cut)),
            "contactEmail" : .string(contactEmail),
            "contactName" : .string(contactName),
            "password" : .string(password)
        ])
    }
    
    static func prepare(_ database: Database) throws {
        try database.create(self.entity, closure: { vendor in
            vendor.id()
            vendor.string("name")
            vendor.string("description")
            vendor.string("website")
            vendor.string("email")
            vendor.string("username")
            vendor.double("cut")
            vendor.string("contactEmail")
            vendor.string("contactName")
            vendor.string("password")
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
}
