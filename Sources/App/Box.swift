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

final class Box: Model, Preparation, JSONConvertible {
    
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
    let publish_date: Date
    
    var vendor_id: Node?
    
    init(node: Node, in context: Context) throws {
        id = try node.extract("id")
        name = try node.extract("name")
        breif = try node.extract("breif")
        long_desc = try node.extract("long_desc")
        short_desc = try node.extract("short_desc")
        bullets = try node.extract("bullets") { ($0 as String).components(separatedBy: "\n") }
        freq = try node.extract("freq")
        price = try node.extract("price")
        vendor_id = try node.extract("vendor_id")
        publish_date = try Date(timeIntervalSince1970: TimeInterval(node.extract("publish_date") as Int))
    }
    
    init(id: String? = nil, name: String, breif: String, long_desc: String, short_desc: String, bullets: [String], freq: String, price: Double, vendor_id: String, publish_date: Date) {
        self.id = id.flatMap { .string($0) }
        self.name = name
        self.breif = breif
        self.long_desc = long_desc
        self.short_desc = short_desc
        self.bullets = bullets
        self.freq = freq
        self.vendor_id = .string(vendor_id)
        self.price = price
        self.publish_date = publish_date
    }
    
    func makeNode(context: Context) throws -> Node {
        return try Node(node: [
            "id" : id!,
            "name" : .string(name),
            "breif" : .string(breif),
            "long_desc" : .string(long_desc),
            "short_desc" : .string(short_desc),
            "bullets" : .array(bullets.map { .string($0) }),
            "freq" : .string(freq),
            "price" : .number(.double(price)),
            "vendor_id" : vendor_id!,
            "publish_date" : .number(.double(publish_date.timeIntervalSince1970))
        ])
    }
    
    static func prepare(_ database: Database) throws {
        try database.create(self.entity, closure: { box in
            box.id()
            box.string("name")
            box.string("long_desc", length: 1000)
            box.string("short_desc")
            box.string("bullets")
            box.string("breif")
            box.string("freq")
            box.double("price")
            box.double("publish_date")
            box.parent(Vendor.self, optional: false)
        })
    }
    
    static func revert(_ database: Database) throws {
        try database.delete(self.entity)
    }
}

extension Box {
    
    func vendor() throws -> Parent<Vendor> {
        return try parent(vendor_id)
    }
    
    func pictures() -> Children<Picture> {
        return children("id", Picture.self)
    }
    
    func reviews() -> Children<Review> {
        return children("id", Review.self)
    }
    
    func categories() throws -> Siblings<Category> {
        return try siblings()
    }
    
    func subscriptions() -> Children<Subscription> {
        return children("id", Subscription.self)
    }
}

final class FeaturedBox: Model, Preparation, JSONConvertible {
    
    var id: Node?
    var exists = false
    
    public static var entity = "featured_boxes"
    
    var box_id: Node?
    
    init(node: Node, in context: Context) throws {
        id = try node.extract("id")
        box_id = try node.extract("box_id")
    }
    
    init(id: String? = nil, boxId: String) {
        self.id = id.flatMap { .string($0) }
        self.box_id = .string(boxId)
    }
    
    func makeNode(context: Context) throws -> Node {
        return try Node(node: [
            "id" : id!,
            "box_id" : box_id!
        ])
    }
    
    static func prepare(_ database: Database) throws {
        try database.create(self.entity, closure: { box in
            box.id()
            box.parent(Box.self, optional: false)
        })
    }
    
    static func revert(_ database: Database) throws {
        try database.delete(self.entity)
    }
}

extension FeaturedBox {
    
    func box() throws -> Parent<Box> {
        return try parent(box_id)
    }
}
