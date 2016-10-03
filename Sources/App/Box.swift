//
//  File.swift
//  subber-api
//
//  Created by Hakon Hanesand on 9/27/16.
//
//

import Vapor
import Fluent
import Foundation

final class Box: Model, Preparation, NodeInitializable, NodeRepresentable, Entity {
    
    var id: Node?
    var exists = false
    
    public static var entity = "boxes"
    
    let name: String
    let breif: String
    let long_desc: String
    let short_desc: String
    let bullets: [String]
    let freq: String
    let price: Double
    
    var vendorId: Node?
    
    init(node: Node, in context: Context) throws {
        id = try node.extract("id")
        name = try node.extract("name")
        breif = try node.extract("breif")
        long_desc = try node.extract("long_desc")
        short_desc = try node.extract("short_desc")
        bullets = try node.extract("bullets") { ($0 as String).components(separatedBy: "\n") }
        freq = try node.extract("freq")
        price = try node.extract("price")
        vendorId = try node.extract("vendorId")
    }
    
    init(id: String? = nil, name: String, breif: String, long_desc: String, short_desc: String, bullets: [String], freq: String, price: Double, vendorId: String) {
        self.id = id.flatMap { .string($0) }
        self.name = name
        self.breif = breif
        self.long_desc = long_desc
        self.short_desc = short_desc
        self.bullets = bullets
        self.freq = freq
        self.vendorId = .string(vendorId)
        self.price = price
    }
    
    func makeNode(context: Context) throws -> Node {
        return try Node(node: [
            "id" : id!,
            "name" : .string(name),
            "breif" : .string(breif),
            "long_desc" : .string(long_desc),
            "short_desc" : .string(short_desc),
            "bullets" : .string(bullets.joined(separator: "\n")),
            "freq" : .string(freq),
            "price" : .number(.double(price)),
            "vendorId" : vendorId!
        ])
    }
    
    static func prepare(_ database: Database) throws {
        try database.create(self.entity, closure: { box in
            box.id()
            box.string("name")
            box.string("long_desc")
            box.string("short_desc")
            box.string("bullets")
            box.string("breif")
            box.string("freq")
            box.double("price")
            box.parent(Vendor.self, optional: false)
        })
    }
    
    static func revert(_ database: Database) throws {
        try database.delete(self.entity)
    }
}

extension Box {
    
    func vendor() throws -> Parent<Vendor> {
        return try parent(vendorId)
    }
    
    func pictures() -> Children<Picture> {
        return children()
    }
    
    func reviews() -> Children<Review> {
        return children()
    }
    
    func categories() throws -> Siblings<Category> {
        return try siblings()
    }
    
    func subscriptions() -> Children<Subscription> {
        return children()
    }
}
