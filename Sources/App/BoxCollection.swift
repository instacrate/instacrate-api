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

final class BoxCollection : RouteCollection, EmptyInitializable {
    
    init () {}
    
    typealias Wrapped = HTTP.Responder
    
    func build<Builder : RouteBuilder>(_ builder: Builder) where Builder.Value == Responder {
        
        builder.group("box") { box in
            
            box.get(Box.self) { request, box in
                return try! box.makeJSON()
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
