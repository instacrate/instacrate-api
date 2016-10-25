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
            
            box.get(Box.self) { request, box in
                var relations = try construct(Box.vendor, Box.pictures, Box.reviews, forBase: box, format: Format.long)
                box.postProcess(result: &relations.0, relations: (relations.1, relations.2.array, relations.3.array))
                return try JSON(node: relations.0)
            }
            
            box.group("short") { shortBox in
                
                shortBox.get(Box.self) { request, box in
                    var relations = try construct(Box.vendor, Box.pictures, Box.reviews, forBase: box, format: Format.short)
                    box.postProcess(result: &relations.0, relations: (relations.1, relations.2.array, relations.3.array))
                    return try JSON(node: relations.0)
                }
                
                shortBox.get("category", Category.self) { request, category in
                    let boxes = try category.boxes().all()
                    
                    // TODO : Make concurrent
                    // TODO : Optimize queries based on information needed
                    // TODO : Deduplicate code
                    
                    return try JSON(node: .array(boxes.map { box in
                        var relations = try construct(Box.vendor, Box.pictures, Box.reviews, forBase: box, format: Format.short)
                        box.postProcess(result: &relations.0, relations: (relations.1, relations.2.array, relations.3.array))
                        return relations.0
                    }))
                }
                
                shortBox.get("featured") { request in
                    let boxes = try FeaturedBox.all().flatMap { try $0.box().get() }
                    
                    return try JSON(node: .array(boxes.map { box in
                        var relations = try construct(Box.vendor, Box.pictures, Box.reviews, forBase: box, format: Format.short)
                        box.postProcess(result: &relations.0, relations: (relations.1, relations.2.array, relations.3.array))
                        return relations.0
                    }))
                }
                
                shortBox.get("new") { request in
                    
                    let query = try Box.query().sort("publish_date", .descending)
                    query.limit = Limit(count: 10)
                    
                    let boxes = try query.all()
                    
                    return try JSON(node: .array(boxes.map { box in
                        var relations = try construct(Box.vendor, Box.pictures, Box.reviews, forBase: box, format: Format.short)
                        box.postProcess(result: &relations.0, relations: (relations.1, relations.2.array, relations.3.array))
                        return relations.0
                    }))
                }
                
                shortBox.get("all") { request in
                    
                    let boxes = try Box.query().all()
                    
                    return try JSON(node: .array(boxes.map { box in
                        var relations = try construct(Box.vendor, Box.pictures, Box.reviews, forBase: box, format: Format.short)
                        box.postProcess(result: &relations.0, relations: (relations.1, relations.2.array, relations.3.array))
                        return relations.0
                    }))
                }

                shortBox.get() { request in
                    
                    guard let ids = request.query?["id"]?.array?.flatMap({ $0.string }) else {
                        throw Abort.custom(status: .badRequest, message: "Expected query parameter with name id.")
                    }
                    
                    let boxes = try Box.query().filter("id", .in, ids).all()
                    
                    return try JSON(node: .array(boxes.map { box in
                        var relations = try construct(Box.vendor, Box.pictures, Box.reviews, forBase: box, format: Format.short)
                        box.postProcess(result: &relations.0, relations: (relations.1, relations.2.array, relations.3.array))
                        return relations.0
                    }))
                }
            }
        }
    }
}
