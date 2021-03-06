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
import Sanitized

enum ModelError: Error, CustomStringConvertible {
    
    case missingLink(from: Model.Type, to: Model.Type, id: Int?)
    case ownerMismatch(from: Model.Type, to: Model.Type, fromId: Int?, toId: Int?)
    
    var description: String {
        switch self {
        case let .missingLink(from, to, id):
            return "Missing relation from \(from) to \(to) with foreign id \(id ?? 0)."
        case let .ownerMismatch(from, to, fromId, toId):
            return "The object on \(to) linked from \(from) is not owned by the \(from)'s #\(fromId ?? 0). It is owned by \(toId ?? 0)"
        }
    }
}

final class Box: Model, Preparation, JSONConvertible, Sanitizable {
    
    static var permitted = ["name", "brief", "long_desc", "short_desc", "bullets", "price", "vendor_id", "plan_id", "publish_date"]
    static let boxBulletSeparator = "<<<>>>"
    
    public static var entity = "boxes"
    
    var id: Node?
    var exists = false
    
    let name: String
    let brief: String
    let long_desc: String
    let short_desc: String
    var bullets: [String]
    let price: Double
    let publish_date: Date
    let type: String?
    
    var plan_id: String?
    var vendor_id: Node?
    
    init(node: Node, in context: Context) throws {
        id = try? node.extract("id")
        name = try node.extract("name")
        brief = try node.extract("brief")
        long_desc = try node.extract("long_desc")
        short_desc = try node.extract("short_desc")
        
        if let bullets = node["bullets"] {
            switch bullets {
            case let .array(strings):
                self.bullets = strings.map { String(describing: $0) }
            case let .string(bullets):
                self.bullets = bullets.components(separatedBy: Box.boxBulletSeparator)
            default:
                throw Abort.custom(status: .badRequest, message: "Unknown format for bullets... got \(bullets)")
            }
        }
        bullets = try node.extract("bullets")
        price = try node.extract("price")
        vendor_id = try node.extract("vendor_id")
        publish_date = (try? node.extract("publish_date")) ?? Date()
        plan_id = try? node.extract("plan_id")
        type = try? node.extract("type")
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
        ]).add(objects: [
            "id" : id,
             "plan_id" : plan_id,
             "type" : type
        ])
    }
    
    func postValidate() throws {
        guard (try? vendor().first()) ?? nil != nil else {
            throw ModelError.missingLink(from: Box.self, to: Vendor.self, id: vendor_id?.int)
        }
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
            box.string("type")
            box.parent(Vendor.self, optional: false)
        })
    }
    
    static func revert(_ database: Database) throws {
        try database.delete(self.entity)
    }
    
    func fetchConnectPlan(for vendor: Vendor) throws -> String {
        if let connectAccountPlan = try self.connectAccountPlans().filter("vendor_id", vendor.throwableId()).first() {
            return connectAccountPlan.plan_id
        } else {
            guard let secret = vendor.keys?.secret else {
                throw Abort.custom(status: .internalServerError, message: "Missing secret keys for vendor. \(vendor.id?.int ?? 0)")
            }
            
            let plan = try Stripe.shared.createPlanFor(box: self, on: secret)
            
            var boxPlan = try BoxPlan(box: self, plan_id: plan.id, vendor: vendor)
            try boxPlan.save()
            
            return boxPlan.plan_id
        }
    }
}

extension Box {
    
    func vendor() throws -> Parent<Vendor> {
        return try parent(vendor_id)
    }
    
    func pictures() -> Children<Picture> {
        return fix_children()
    }
    
    func reviews() -> Children<Review> {
        return fix_children()
    }
    
    func categories() throws -> Siblings<Category> {
        return try siblings()
    }
    
    func subscriptions() -> Children<Subscription> {
        return fix_children()
    }
    
    func connectAccountPlans() -> Children<BoxPlan> {
        return fix_children()
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

