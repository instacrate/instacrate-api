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

final class BoxCollection : RouteCollection, EmptyInitializable {
    
    init () {}
    
    typealias Wrapped = HTTP.Responder
    
    func build<Builder : RouteBuilder>(_ builder: Builder) where Builder.Value == Responder {
        
        builder.group("box") { box in
            
            box.get("short", Box.self) { request, box in
                
                let (vendor, reviews, pictures) = try box.gatherRelations()
                let ratings = reviews.map { $0.rating }
                
                guard let picture = pictures.first else {
                    throw Abort.custom(status: .internalServerError, message: "Box has no pictures.")
                }
                
                return try JSON(Node(node : [
                    "name" : .string(box.name),
                    "short_desc" : .string(box.short_desc),
                    "vendor_name" : .string(vendor.name),
                    "price" : .number(.double(box.price)),
                    "picture" : .string(picture.url),
                    "averageRating" : .number(.double(ratings.average))
                ]))
            }
            
            box.get(Box.self) { request, box in
                let (vendor, reviews, pictures) = try box.gatherRelations()
                
                return try JSON(Node(node : [
                    "box" : box.makeNode(),
                    "vendor" : vendor.makeNode(),
                    "reviews" : .array(reviews.map { try $0.makeNode() }),
                    "pictures" : .array(pictures.map { try $0.makeNode() })
                ] as [String : Node]))
            }
            
            box.get("category", Category.self) { request, category in
                return try category.boxes().all().makeJSON()
            }
            
            box.get("featured") { request in
                return try FeaturedBox.all().makeJSON()
            }
            
            box.get("new") { request in
                let calendar = Calendar.current
                let oneWeekAgo = calendar.date(byAdding: .day, value: -2 * 7, to: Date())!
                let query = try Box.query().filter("publish_date", .greaterThan, oneWeekAgo.timeIntervalSince1970)
                
                return try query.all().makeJSON()
            }
            
            box.get() { request in
                
                guard let ids = request.query?["id"]?.array?.flatMap({ $0.string }) else {
                    throw Abort.custom(status: .badRequest, message: "Expected query parameter with name id.")
                }
                
                return try Box.query().filter("id", .in, ids).all().makeJSON()
            }
            
            box.post("create") { request in
                
                guard let json = request.json else {
                    throw Abort.badRequest
                }
                
                guard var box = try? Box(json: json) else {
                    throw Abort.badRequest
                }
                
                try box.save()
                
                return try box.makeJSON()
            }
        }
    }
}
