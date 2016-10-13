//
//  Entity+Relation.swift
//  subber-api
//
//  Created by Hakon Hanesand on 9/28/16.
//
//

import Fluent
import Vapor

extension Box {
    
    func queryForRelation<T: Model>() throws -> Query<T> {
        switch T.self {
        case is Review.Type, is Picture.Type:
            return try children().makeQuery()
        case is Vendor.Type:
            return try parent(vendor_id).makeQuery()
        default:
            throw Abort.custom(status: .internalServerError, message: "No such relation for box")
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
    
    fileprivate func runRelationQuery<T : Model>(relation: T.Type, withFormat format: Format) throws -> [T] {
        let query: Query<T> = try queryForRelation()
        format.optimize(query: query)
        return try query.run()
    }
    
    public func relations(forFormat format: Format) throws -> (Vendor, [Review], [Picture]) {
        
        let vendor = try self.runRelationQuery(relation: Vendor.self, withFormat: format).first!
        let pictures = try self.runRelationQuery(relation: Picture.self, withFormat: format)
        let reviews = try self.runRelationQuery(relation: Review.self, withFormat: format)
        
        return (vendor, reviews, pictures)
    }
    
    public func response(forFormat format: Format, _ vendor: Vendor, _ reviews: [Review], _ pictures: [Picture]) throws -> Node {
        
        switch format {
        case .short:
            let averageRating = reviews.map { $0.rating }.average
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
                "box" : self.makeNode(),
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
