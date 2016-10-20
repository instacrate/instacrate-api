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

fileprivate func createShortNode(box: Box, vendor: Vendor, reviews: [Review], picture: Picture) throws -> Node {
    return try Node(node : [
        "name" : .string(box.name),
        "short_desc" : .string(box.short_desc),
        "vendor_name" : .string(vendor.name),
        "price" : .number(.double(box.price)),
        "picture" : .string(picture.url),
        "averageRating" : .number(.double(reviews.map { $0.rating }.average))
    ])
}

fileprivate func createExtensiveNode(box: Box, vendor: Vendor, reviews: [Review], pictures: [Picture]) throws -> Node {
    return try Node(node : [
        "box" : box.makeNode(),
        "vendor" : vendor.makeNode(),
        "reviews" : .array(reviews.map { try $0.makeNode() }),
        "pictures" : .array(pictures.map { try $0.makeNode() })
    ])
}

final class BoxCollection : RouteCollection, EmptyInitializable {
    
    init () {}
    
    typealias Wrapped = HTTP.Responder
    
    func build<Builder : RouteBuilder>(_ builder: Builder) where Builder.Value == Responder {
        
        builder.group("box") { box in
            
            box.get(Box.self) { request, box in
                let (vendor, pictures, reviews, users) = try box.relations(forFormat: Format.short)
                return try JSON(node: box.response(forFormat: .long, vendor, pictures, reviews, users))
            }
            
            box.post("create") { request in
                
                guard let json = request.json else {
                    throw Abort.custom(status: .badRequest, message: "Missing or invalid JSON in HTTP body : \(request)")
                }
                
                var box = try Box(json: json)
                try box.save()
                
                return Response(status: .created)
            }
            
            box.group("short") { shortBox in
                
                shortBox.get(Box.self) { request, box in
                    
                    let (vendor, pictures, reviews, users) = try box.relations(forFormat: Format.short)
                    return try JSON(node: try box.response(forFormat: .short, vendor, pictures, reviews, users))
                }
                
                shortBox.get("category", Category.self) { request, category in
                    let boxes = try category.boxes().all()
                    
                    // TODO : Make concurrent
                    // TODO : Optimize queries based on information needed
                    // TODO : Deduplicate code
                    
                    return try JSON(node: .array(boxes.map { box in
                        let (vendor, pictures, reviews, users) = try box.relations(forFormat: Format.short)
                        return try box.response(forFormat: Format.short, vendor, pictures, reviews, users)
                    }))
                }
                
                shortBox.get("featured") { request in
                    let boxes = try FeaturedBox.all().flatMap { try $0.box().get() }
                    
                    return try JSON(node: .array(boxes.map { box in
                        let (vendor, pictures, reviews, users) = try box.relations(forFormat: Format.short)
                        return try box.response(forFormat: Format.short, vendor, pictures, reviews, users)
                    }))
                }
                
                shortBox.get("new") { request in
                    
                    let query = try Box.query().sort("publish_date", .descending)
                    query.limit = Limit(count: 10)
                    
                    let boxes = try query.all()
                    
                    return try JSON(node: .array(boxes.map { box in
                        let (vendor, pictures, reviews, users) = try box.relations(forFormat: Format.short)
                        return try box.response(forFormat: Format.short, vendor, pictures, reviews, users)
                    }))
                }
                
                shortBox.get("all") { request in
                    
                    let boxes = try Box.query().all()
                    
                    return try JSON(node: .array(boxes.map { box in
                        let (vendor, pictures, reviews, users) = try box.relations(forFormat: Format.short)
                        return try box.response(forFormat: Format.short, vendor, pictures, reviews, users)
                    }))
                }

                shortBox.get() { request in
                    
                    guard let ids = request.query?["id"]?.array?.flatMap({ $0.string }) else {
                        throw Abort.custom(status: .badRequest, message: "Expected query parameter with name id.")
                    }
                    
                    let boxes = try Box.query().filter("id", .in, ids).all()
                    
                    return try JSON(node: .array(boxes.map { box in
                        let (vendor, pictures, reviews, users) = try box.relations(forFormat: Format.short)
                        return try box.response(forFormat: Format.short, vendor, pictures, reviews, users)
                    }))
                }
            }
        }
    }
}
