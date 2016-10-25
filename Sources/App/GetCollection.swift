//
//  File.swift
//  subber-api
//
//  Created by Hakon Hanesand on 10/24/16.
//
//

import Foundation
import Vapor
import HTTP
import Routing
import JSON
import Auth

final class GetCollection : RouteCollection, EmptyInitializable {
    
    init () {}
    
    typealias Wrapped = HTTP.Responder
    
    func build<Builder : RouteBuilder>(_ builder: Builder) where Builder.Value == Responder {
        
        builder.get("box", Box.self) { request, box in
            return try box.makeJSON()
        }
        
        builder.get("vendor", Vendor.self) { request, vendor in
            return try vendor.makeJSON()
        }
        
        builder.get("user", User.self) { request, user in
            return try user.makeJSON()
        }
        
        builder.get("session", Picture.self) { request, session in
            return try session.makeJSON()
        }
        
        builder.get("review", Review.self) { request, review in
            return try review.makeJSON()
        }
        
        builder.get("order", Order.self) { request, order in
            return try order.makeJSON()
        }
        
        builder.get("category", Category.self) { request, category in
            return try category.makeJSON()
        }
    }
}

