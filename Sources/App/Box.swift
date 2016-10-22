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
        bullets = (try node.extract("bullets") as String).replacingOccurrences(of: "\\n", with: "\n").components(separatedBy: "\n")
        freq = try node.extract("freq")
        price = try node.extract("price")
        vendor_id = try node.extract("vendor_id")
        publish_date = try Date(timeIntervalSince1970: TimeInterval(node.extract("publish_date") as Int))
    }
    
    init(id: String? = nil, name: String, brief: String, long_desc: String, short_desc: String, bullets: [String], freq: String, price: Double, vendor_id: String, publish_date: Date) {
        self.id = id.flatMap { .string($0) }
        self.name = name
        self.brief = brief
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
    
    typealias vendorNode = AnyRelationNode<Box, Vendor, One>
    typealias pictureNode = AnyRelationNode<Box, Picture, Many>
    typealias reviewNode = AnyRelationNode<Box, Review, Many>
    
    func queryForRelation<R: Relation>(relation: R.Type) throws -> Query<R.Target> {
        switch R.self {
        case is pictureNode.Rel.Type, is reviewNode.Rel.Type:
            return try children().makeQuery()
        case is vendorNode.Rel.Type:
            return try parent(vendor_id).makeQuery()
        default:
            throw Abort.custom(status: .internalServerError, message: "No such relation for box")
        }
    }
    
    public func relations(forFormat format: Format) throws -> (Vendor, [Picture], [Review], [User]) {
        
        let (reviews, users) = try evaluate(forFormat: format, first: reviewNode.self, second: Review.userNode.self)
        let vendor = try vendorNode.run(onModel: self, forFormat: format)
        let pictures = try pictureNode.run(onModel: self, forFormat: format)
        
        return (vendor, pictures, reviews, users)
    }
    
    public func response(forFormat format: Format, _ vendor: Vendor, _ pictures: [Picture], _ reviews: [Review], _ users: [User]) throws -> Node {
        
        let averageRating = reviews.map { $0.rating }.average
        
        switch format {
        case .short:
            guard let picture = pictures.first else {
                throw Abort.custom(status: .internalServerError, message: "Missing picture for box \(self)")
            }
            
            return try Node(node : [
                "name" : .string(name),
                "brief" : .string(brief),
                "vendor_name" : .string(vendor.name),
                "price" : .number(.double(price)),
                "picture" : .string(picture.url),
                "averageRating" : .number(.double(averageRating)),
                "id" : id!,
                "freq" : .string(freq),
                "numberOfRatings" : .number(.int(reviews.count))
            ])
        case .long:
            
            let review_node = try zip(reviews, users).map { review, user in
                return try review.makeNode().add(name: "user", node: user.makeNode())
            }
            
            return try Node(node : [
                "box" : self.makeNode().add(objects: ["averageRating" : averageRating,
                                                      "numberOfRatings" : reviews.count]),
                "vendor" : vendor.makeNode(),
                "reviews" : .array(review_node),
                "pictures" : .array(pictures.map { try $0.makeNode() })
            ])
        }
    }
}


