//
//  LongBoxViewCollection.swift
//  subber-api
//
//  Created by Hakon Hanesand on 11/18/16.
//
//

import Foundation
import Vapor
import HTTP
import Routing
import Fluent

extension Node {
    
    mutating func substitute(key: String, model: Model) throws -> Node {
        precondition(!key.hasSuffix("_id"))
        
        self["\(key)_id"] = nil
        self[key] = try model.makeNode()
        
        return self
    }
}

final class LongBoxViewCollection: BaseViewCollection {
    
    func createTerseView(forRequest request: Request, box: Box) throws -> ResponseRepresentable {
        let relations = try box.relations()
        
        let reviewNodes = try Node(node: relations.reviews.map { review -> Node in
            var node = try review.makeNode()
            return try node.substitute(key: "customer", model: review.user())
        })
        
        let nodes = try [
            "vendor" : relations.vendor,
            "reviews" : reviewNodes,
            "pictures" : Node(node: relations.pictures),
            "numberOfRatings" : relations.reviews.count,
            "averageRating" : relations.reviews.map { $0.rating }.average
        ] as [String : NodeConvertible?]
        
        return try box.makeNode().add(objects: nodes).makeJSON()
    }
    
    func build<Builder : RouteBuilder>(_ builder: Builder) where Builder.Value == Wrapped {
        
        builder.get("box", "long", Box.self) { request, box in
            return try self.createTerseView(forRequest: request, box: box)
        }
    }
}
