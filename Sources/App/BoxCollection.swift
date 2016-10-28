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

fileprivate func createShortNode(forBox box: Box) throws -> Node {
    let relations = try box.relations()

    guard let picture = relations.pictures.first else {
        throw Abort.custom(status: .internalServerError, message: "Missing picture for box with id \(box.id) and name \(box.name).")
    }
    
    return try Node(node : [
        "name" : .string(box.name),
        "brief" : .string(box.brief),
        "vendor_name" : .string(relations.vendor.businessName),
        "price" : .number(.double(box.price)),
        "picture" : .string(picture.url),
        "averageRating" : .number(.double(relations.reviews.map { $0.rating }.average)),
        "frequency" : .string(box.freq),
        "numberOfReviews" : .number(.int(relations.reviews.count))
    ]).add(name: "id", node: box.id)
}

fileprivate func createExtensiveNode(forBox box: Box) throws -> Node {
    let relations = try box.relations()
    
    return try Node(node : [
        "box" : box.makeNode(),
        "vendor" : relations.vendor.makeNode(),
        "reviews" : .array(relations.reviews.map { try $0.makeNode() }),
        "pictures" : .array(relations.pictures.map { try $0.makeNode() })
    ])
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

final class BoxCollection : RouteCollection, EmptyInitializable {
    
    init () {}
    
    typealias Wrapped = HTTP.Responder
    
    func build<Builder : RouteBuilder>(_ builder: Builder) where Builder.Value == Responder {
        
        builder.group("box") { box in
            
            box.get(Box.self) { request, box in
                return try createExtensiveNode(forBox: box)
            }
            
            let short = box.grouped("short")
            
            short.get(Box.self) { request, box in
                return try createShortNode(forBox: box)
            }
            
            short.get("category", Category.self) { request, category in
                let boxes = try category.boxes().all()

                return try JSON(node: .array(boxes.map { box in
                    return try createShortNode(forBox: box)
                }))
            }
            
            short.get("featured") { request in
                let boxes = try FeaturedBox.all().flatMap { try $0.box().get() }
                return try Node.array(boxes.map(createShortNode(forBox:)))
            }
            
            short.get("new") { request in
                let query = try Box.query().sort("publish_date", .descending)
                query.limit = Limit(count: 10)
                
                let boxes = try query.all()
                
                return try Node.array(boxes.map(createShortNode(forBox:)))
            }
            
            short.get("all") { request in
                let boxes = try Box.query().all()
                return try Node.array(boxes.map(createShortNode(forBox:)))
            }

            short.get() { request in
                
                guard let ids = request.query?["id"]?.array?.flatMap({ $0.string }) else {
                    throw Abort.custom(status: .badRequest, message: "Expected query parameter with name id.")
                }
                
                let boxes = try Box.query().filter("id", .in, ids).all()
                return try Node.array(boxes.map(createShortNode(forBox:)))
            }
        }
    }
}
