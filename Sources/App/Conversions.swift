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
    
    typealias vendorNode = AnyRelationNode<Box, SingularRelation<Vendor>>
    typealias pictureNode = AnyRelationNode<Box, ManyRelation<Picture>>
    typealias reviewNode = AnyRelationNode<Box, ManyRelation<Review>>

    func queryForRelation<R: Relation>(relation: R.Type) throws -> Query<R.Input> {
        switch R.self {
        case is pictureNode.Next.Type, is reviewNode.Next.Type:
            return try children().makeQuery()
        case is vendorNode.Next.Type:
            return try parent(vendor_id).makeQuery()
        default:
            throw Abort.custom(status: .internalServerError, message: "No such relation for box")
        }
    }
    
    public func relations(forFormat format: Format) throws -> (Vendor, [Review], [Picture]) {
    
        let vendor = try vendorNode.run(withFormat: format, model: self)
        let pictures = try pictureNode.run(withFormat: format, model: self)
        let reviews = try reviewNode.run(withFormat: format, model: self)
        
        return (vendor, reviews, pictures)
    }
    
    public func response(forFormat format: Format, _ vendor: Vendor, _ reviews: [Review], _ pictures: [Picture]) throws -> Node {
        
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
            
            return try Node(node : [
                "box" : self.makeNode().add(objects: ["averageRating" : .number(.double(averageRating)),
                                                      "numberOfRatings" : .number(.int(reviews.count))]),
                "vendor" : vendor.makeNode(),
                "reviews" : .array(reviews.map { try $0.makeNode() }),
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
