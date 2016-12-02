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

extension Node {

    public func extract_<T : NodeInitializable>(_ path: PathIndex...) throws -> T {
        return try extract_(path)
    }

    public func extract_<T : NodeInitializable>(_ path: [PathIndex]) throws -> T {
        guard let value = node[path] else {
            let pathDescription = path.map { String(describing: $0) }.joined(separator: ", ")
            throw try NodeError.unableToConvert(node: nil, expected: "Expected value of type \(T.self) at \(pathDescription) on \(node.makeJSON().object).")
        }

        return try T(node: value)
    }
}

final class Box: Model, Preparation, JSONConvertible, FastInitializable {
    
    static var requiredJSONFields = ["name", "brief", "long_desc", "short_desc", "bullets", "freq", "price", "vendor_id"]
    static let boxBulletSeparator = "<<<>>>"
    
    var id: Node?
    var exists = false
    
    public static var entity = "boxes"
    
    let name: String
    let brief: String
    let long_desc: String
    let short_desc: String
    var bullets: [String]
    let price: Double
    let publish_date: Date
    
    var plan_id: String?
    
    var vendor_id: Node?
    
    init(node: Node, in context: Context) throws {
        id = try? node.extract_("id")
        name = try node.extract_("name")
        brief = try node.extract_("brief")
        long_desc = try node.extract_("long_desc")
        short_desc = try node.extract_("short_desc")
        
        let string = try node.extract("bullets") as String
        bullets = string.components(separatedBy: Box.boxBulletSeparator)

        price = try node.extract_("price")
        vendor_id = try node.extract("vendor_id")
        publish_date = (try? node.extract_("publish_date")) ?? Date()
        plan_id = try? node.extract_("plan_id")
    }
    
    func makeNode(context: Context) throws -> Node {
        return try Node(node: [
            "name" : .string(name),
            "brief" : .string(brief),
            "long_desc" : .string(long_desc),
            "short_desc" : .string(short_desc),
            "bullets" : .string(bullets.joined(separator: Box.boxBulletSeparator)),
            "price" : .number(.double(price)),
            "vendor_id" : vendor_id!,
            "publish_date" : .string(publish_date.ISO8601String),
            ]).add(objects: ["id" : id,
                         "plan_id" : plan_id])
    }
    
    static func prepare(_ database: Database) throws {
        try database.create(self.entity, closure: { box in
            box.id()
            box.string("name")
            box.string("long_desc", length: 1000)
            box.string("short_desc")
            box.string("bullets")
            box.string("brief")
            box.double("price")
            box.double("publish_date")
            box.string("plan_id")
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

