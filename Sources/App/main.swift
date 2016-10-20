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
import Foundation
import Auth

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

let drop = Droplet.create()

// Add the box endpoint
drop.collection(BoxCollection.self)
drop.collection(AuthCollection.self)
drop.collection(OrderCollection.self)
drop.collection(ValidationCollection.self)
drop.collection(CreationCollection.self)

drop.run()

