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

import HTTP

final class Box: Model, Preparation, JSONConvertible, FastInitializable {
    
    static var requiredJSONFields = ["name", "brief", "long_desc", "short_desc", "bullets", "freq", "price", "vendor_id"]
    
    var id: Node?
    var exists = false
    
    public static var entity = "boxes"
    
    let name: String
    let brief: String
    let long_desc: String
    let short_desc: String
    let bullets: [String]
    let freq: String
    let price: Double
    let publish_date: Date
    
    var vendor_id: Node?
    
    init(node: Node, in context: Context) throws {
        id = try? node.extract("id")
        name = try node.extract("name")
        brief = try node.extract("brief")
        long_desc = try node.extract("long_desc")
        short_desc = try node.extract("short_desc")
        bullets = try node.extract("bullets")
        freq = try node.extract("freq")
        price = try node.extract("price")
        vendor_id = try node.extract("vendor_id")
        publish_date = (try? node.extract("publish_date")) ?? Date()
    }
    
    func makeNode(context: Context) throws -> Node {
        return try Node(node: [
            "name" : .string(name),
            "brief" : .string(brief),
            "long_desc" : .string(long_desc),
            "short_desc" : .string(short_desc),
            "bullets" : .array(bullets.map { .string($0) }),
            "freq" : .string(freq),
            "price" : .number(.double(price)),
            "vendor_id" : vendor_id!,
            "publish_date" : .number(.double(publish_date.timeIntervalSince1970))
        ]).add(name: "id", node: id)
    }
    
    static func prepare(_ database: Database) throws {
        try database.create(self.entity, closure: { box in
            box.id()
            box.string("name")
            box.string("long_desc", length: 1000)
            box.string("short_desc")
            box.string("bullets")
            box.string("brief")
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
        return children("box_id", Picture.self)
    }
    
    func reviews() -> Children<Review> {
        return children("box_id", Review.self)
    }
    
    func categories() throws -> Siblings<Category> {
        return try siblings()
    }
    
    func subscriptions() -> Children<Subscription> {
        return children("box_id", Subscription.self)
    }
}

extension Box: Relationable {

    typealias Relations = (vendor: Vendor, pictures: [Picture], reviews: [Review])
    
    func relations() throws -> (vendor: Vendor, pictures: [Picture], reviews: [Review]) {
        guard let vendor = try self.vendor().get() else {
            throw Abort.custom(status: .internalServerError, message: "Missing vendor for box with id \(id!)")
        }
        
        let pictures = try self.pictures().all()
        let reviews = try self.reviews().all()
        
        return (vendor, pictures, reviews)
    }
}


