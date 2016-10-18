//
//  Entity+Relation.swift
//  subber-api
//
//  Created by Hakon Hanesand on 9/28/16.
//
//

import Fluent
import Vapor

extension Node {
    
    func add(name: String, node: Node?) throws -> Node {
        if let node = node {
            return try add(name: name, node: node)
        }
        
        return self
    }
    
    func add(name: String, node: Node) throws -> Node {
        guard var object = self.nodeObject else { throw NodeError.unableToConvert(node: self, expected: "[String: Node].self") }
        object[name] = node
        return try Node(node: object)
    }
    
    func add(objects: [String : Node]) throws -> Node {
        guard var nodeObject = self.nodeObject else { throw NodeError.unableToConvert(node: self, expected: "[String: Node].self") }

        for (name, object) in objects {
            nodeObject[name] = object
        }
        
        return try Node(node: nodeObject)
    }
}

enum Format {
    case short
    case long
    
    func optimize<T : Model>(query: Query<T>) {
        switch self {
            
        case .short:
            
            switch T.self {
                
            case is Picture.Type:
                query.limit = Limit(count: 1)
                
            default: break
                
            }
            
        default: break
        }
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
                throw Abort.custom(status: .internalServerError, message: "Missing picture for box")
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
                "box" : self.makeNode().add(objects: ["averageRating" : .number(.double(averageRating)),
                                                      "numberOfRatings" : .number(.int(reviews.count))]),
                "vendor" : vendor.makeNode(),
                "reviews" : .array(review_node),
                "pictures" : .array(pictures.map { try $0.makeNode() })
            ])
        }
    }
}

extension Array where Element : NodeRepresentable {
    
    public func makeJSON() throws -> JSON {
        let node = try Node.array(self.map { try $0.makeNode() })
        return try JSON(node: node)
    }
}

extension Array where Element : NodeInitializable {
    
    public init(json: JSON) throws {
        let node = json.makeNode()
        try self.init(node: node)
    }
}
