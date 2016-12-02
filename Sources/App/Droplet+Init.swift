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
import Auth
import Turnstile
import HTTP
import Console

extension SessionsMiddleware {
    
    class func createSessionsMiddleware() -> SessionsMiddleware {
        let memory = MemorySessions()
        return SessionsMiddleware(sessions: memory)
    }
}

extension Droplet {
    
    static var instance: Droplet?
    
    internal static func create() -> Droplet {
        
        let drop = Droplet()
        
        try! drop.addProvider(VaporMySQL.Provider.self)
        
        drop.addConfigurable(middleware: SessionsMiddleware.createSessionsMiddleware(), name: "sessions")
        drop.addConfigurable(middleware: UserAuthMiddleware(), name: "userAuth")
        drop.addConfigurable(middleware: VendorAuthMiddleware(), name: "userAuth")
        drop.addConfigurable(middleware: LoggingMiddleware(), name: "logger")
        
        let preparations: [Preparation.Type] = [Box.self, Review.self, Vendor.self, Category.self, Picture.self, Order.self, Shipping.self, Subscription.self, Pivot<Box, Category>.self, Customer.self, Session.self, FeaturedBox.self]
        drop.preparations.append(contentsOf: preparations)
        
        Droplet.instance = drop
        return drop
    }
    
    static let userProtect = UserProtectMiddleware()
    static let vendorProtect = VendorProtectMiddleware()
    
    static func protect(_ type: SessionType) -> Middleware {
        switch type {
        case .customer: return userProtect
        case .vendor: return vendorProtect
        case .none: return userProtect
        }
    }
}
