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

drop.get { request in
    return try! Box.find(1)!.makeJSON()
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
        
        return try! order.makeJSON()
    }
}


drop.run()
