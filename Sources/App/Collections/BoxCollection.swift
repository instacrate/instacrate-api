//
//  ShippingController.swift
//  subber-api
//
//  Created by Hakon Hanesand on 10/1/16.
//
//

import Foundation
import Vapor
import HTTP
import Routing
import JSON
import Node
import Fluent

extension Collection where Iterator.Element == Int, IndexDistance == Int {
    
    var total: Iterator.Element {
        return reduce(0, +)
    }
    
    var average: Double {
        return isEmpty ? 0 : Double(total) / Double(count)
    }
}

fileprivate func createNode(forBox box: Box) throws -> Node {
    let relations = try box.relations()
    
    let reviewNodes = try relations.reviews.map { review -> Node in
        guard let user = try review.user().get() else {
            throw Abort.custom(status: .notFound, message: "User relation missing for review with text \(review.text)")
        }
        
        var node = try review.makeNode()
        
        node["customer_id"] = nil
        node["user"] = try user.makeNode()
        
        return node
    }
    
    let nodes = try [
        "vendor" : relations.vendor.makeNode(),
        "reviews" : .array(reviewNodes),
        "pictures" : .array(relations.pictures.map { try $0.makeNode() }),
        "numberOfRatings" : .number(.int(relations.reviews.count)),
        "averageRating" : .number(.double(relations.reviews.map { $0.rating }.average))
    ]
    
    return try box.makeNode().add(objects: nodes)
}

extension Node: JSONRepresentable {
    
    public func makeJSON() throws -> JSON {
        return try JSON(node: self)
    }
}

extension Node: ResponseRepresentable {
    
    public func makeResponse() throws -> Response {
        let json = try makeJSON()
        return try json.makeResponse()
    }
}
