//
//  Main.swift
//  subber-api
//
//  Created by Hakon Hanesand on 9/26/16.
//
//

import Vapor
import Fluent
import Node
import HTTP
import Turnstile
import Auth
import Foundation

let drop = Droplet.create()

extension Request {
    func subject() throws -> Subject {
        guard let subject = storage["subject"] as? Subject else {
            throw AuthError.noSubject
        }
        
        return subject
    }
}

extension Polymorphic {
    
    func array<T>() -> [T]? {
        return array?.map { $0 as! T }
    }
}

// Add the box endpoint
drop.collection(BoxCollection.self)

drop.group("auth") { auth in
    
    auth.post("login") { request in
        guard let credentials = request.auth.header?.basic else {
            throw Abort.badRequest
        }
        
        try request.auth.login(credentials)
        
        if let _ = try? request.subject() {
            return "OK"
        } else {
            throw AuthError.invalidBasicAuthorization
        }
    }
}

drop.grouped(drop.protect()).group("order") { order in
    
    order.post(Subscription.self, Shipping.self) { request, subscription, shipping in
        
        var order = Order(subscription: subscription, shipping: shipping)
        try? order.save()
        
        guard order.id != nil else {
            throw Abort.custom(status: .internalServerError, message: "Error saving new order to database")
        }
        
        return order.makeJSON()
    }
    
}

drop.group("box") { box in
    
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


drop.run()
