//
//  Droplet+Init.swift
//  subber-api
//
//  Created by Hakon Hanesand on 9/28/16.
//
//

import Foundation
import Vapor
import Sessions
import VaporMySQL
import Fluent

extension SessionsMiddleware {
    
    class func createSessionsMiddleware() -> SessionsMiddleware {
        let memory = MemorySessions()
        return SessionsMiddleware(sessions: memory)
    }
}

extension Droplet {
    
    internal static func create() -> Droplet {
        return Droplet(availableMiddleware: ["sessions" : SessionsMiddleware.createSessionsMiddleware()],
                       preparations: [Box.self, Review.self, Vendor.self, Category.self, Picture.self, Order.self, Shipping.self, Subscription.self,
                                      Pivot<Box, Category>.self, User.self, UserSession.self, Pivot<User, UserSession>.self],
                       providers: [VaporMySQL.Provider.self])
    }
}
