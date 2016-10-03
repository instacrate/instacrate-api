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

final class BoxCollection : RouteCollection, EmptyInitializable {
    
    init () {}
    
    typealias Wrapped = HTTP.Responder
    
    func build<Builder : RouteBuilder>(_ builder: Builder) where Builder.Value == Responder {
        
        builder.group("box") { box in
            
            box.get(Box.self) { request, box in
                return box.makeJSON()
            }
            
            box.get("category", Category.self) { request, category in
                return try category.boxes().all().makeJSON()
            }
            
            // TODO
            box.get("featured") { request in
                return try JSON(node: .array([]))
            }
            
            // TODO
            box.get("new") { request in
                return try JSON(node: .array([]))
            }
            
            box.get() { request in
                
                guard let ids = request.query?["id"]?.array?.flatMap({ $0.string }) else {
                    throw Abort.custom(status: .badRequest, message: "Expected query parameter with name id.")
                }
                
                return try Box.query().filter("id", .in, ids).all().makeJSON()
            }
        }
    }
}
