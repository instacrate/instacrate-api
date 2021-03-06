//
//  Box+Definitions.swift
//  subber-api
//
//  Created by Hakon Hanesand on 11/18/16.
//
//

import Foundation
import TypeSafeRouting
import Node
import Fluent
import Vapor
import HTTP

protocol Formatter: TypesafeOptionsParameter {

    associatedtype Input

    func apply(on model: Input) throws -> Node
    func apply(on models: [Input]) throws -> Node
}

extension Box {
    
    enum Curated: String, TypesafeOptionsParameter, QueryRepresentable {
        case featured
        case staffpicks
        case new
        case all
        
        static let key = "curated"
        static let values = [Curated.featured.rawValue, Curated.staffpicks.rawValue, Curated.new.rawValue, Curated.all.rawValue]
        static let defaultValue: Curated? = Curated.all
        
        func makeQuery() throws -> Query<Box> {
            switch self {
            case .all:
                return try Box.query()
                
            case .staffpicks: fallthrough
            case .featured:
                return try Box.query().filter("type", self.rawValue)
                
            case .new:
                let query = try Box.query().sort("publish_date", .descending)
                query.limit = Limit(count: 4)
                return query
            }
        }
    }
    
    enum Sort: String, TypesafeOptionsParameter {
    
        case alphabetical
        case price
        case new
        case none
        
        static let key = "sort"
        static let values = [Sort.alphabetical.rawValue, Sort.price.rawValue, Sort.new.rawValue]
        static let defaultValue: Sort? = Sort.none
        
        var field: String {
            switch self {
            case .alphabetical:
                return "name"
            case .price:
                return "price"
            case .new:
                return "publish_date"
            case .none:
                return ""
            }
        }
        
        func modify<T : Entity>(_ query: Query<T>) throws -> Query<T> {
            if self == .none {
                return query
            }
            
            return try query.sort(field, .ascending)
        }
    }
    
    enum Format: String, Formatter {

        typealias Input = Box
        
        case long
        case short
        
        static let key = "format"
        static let values = ["long", "short"]
        static let defaultValue: Format? = .short
        
        func apply(on model: Box) throws -> Node {
            switch self {
            case .long:
                return try createLongView(forBox: model)
                
            case .short:
                return try createTerseView(forBox: model)
            }
        }
        
        func apply(on models: [Box]) throws -> Node {

            return try Node.array(models.map { (box: Box) -> Node in
                return try self.apply(on: box)
            })
        }
    }
}

fileprivate func createTerseView(forBox box: Box) throws -> Node {
    let boxReviews = try box.reviews().all()
    
    let numberOfReviews = boxReviews.count
    let averageReviewScore = boxReviews.map { $0.rating }.mean()
    
    let vendor = try box.vendor().first()
    let picture = try box.pictures().first()
    
    return try box.makeNode().add(objects: ["numberOfReviews" : numberOfReviews, "averageRating" : averageReviewScore, "vendorName" : vendor?.businessName, "picture" : picture?.url, "bulletSeparator" : Box.boxBulletSeparator])
}

fileprivate func createLongView(forBox box: Box) throws -> Node {
    let relations = try box.relations()
    
    let reviewNodes = try Node(node: relations.reviews.map { review -> Node in
        var node = try review.makeNode()
        
        if let user = try review.customer().first() {
            node = try node.substitute(key: "customer", model: user)
        }
        
        return node
    })
    
    let nodes = try [
        "vendor" : relations.vendor,
        "reviews" : reviewNodes,
        "pictures" : Node(node: relations.pictures),
        "numberOfRatings" : relations.reviews.count,
        "averageRating" : relations.reviews.map { $0.rating }.mean()
    ] as [String : NodeConvertible?]
    
    return try box.makeNode().add(objects: nodes).add(name: "bulletSeparator", node: .string(Box.boxBulletSeparator))
}
