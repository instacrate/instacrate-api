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

extension SessionsMiddleware {
    
    class func createSessionsMiddleware() -> SessionsMiddleware {
        let memory = MemorySessions()
        return SessionsMiddleware(sessions: memory)
    }
}

extension ProtectMiddleware {
    
    class func createProtectionMiddleware() -> ProtectMiddleware {
        let error = Abort.custom(status: .forbidden, message: "Authentication required")
        return ProtectMiddleware(error: error)
    }
}

extension Droplet {
    
    static var instance: Droplet?
    
    internal static func create() -> Droplet {
        let realm = AuthenticatorRealm(User.self)
        let sessionManager = DatabaseSessionManager(realm: realm)
    
        let authenticationMiddleware = AuthMiddleware<User>(turnstile: Turnstile(sessionManager: sessionManager, realm: realm), makeCookie: nil)
        
        let drop = Droplet(availableMiddleware: ["sessions" : SessionsMiddleware.createSessionsMiddleware(),
                                                 "auth" : authenticationMiddleware,
                                                 "protect" : ProtectMiddleware.createProtectionMiddleware()],
                           preparations: [Box.self, Review.self, Vendor.self, Category.self, Picture.self, Order.self, Shipping.self, Subscription.self,
                                      Pivot<Box, Category>.self, User.self, Session.self],
                           providers: [VaporMySQL.Provider.self])
        
        Droplet.instance = drop
        return drop
    }
    
    internal func protect() -> ProtectMiddleware {
        return availableMiddleware["protect"] as! ProtectMiddleware
    }
}
