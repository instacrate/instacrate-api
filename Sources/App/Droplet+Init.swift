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

extension AuthMiddleware {
    
    class func createAuthMiddleware() -> AuthMiddleware<User> {
        let realm = AuthenticatorRealm<User>()
        let sessionManager = DatabaseSessionManager(realm: realm)
        return AuthMiddleware<User>(turnstile: Turnstile(sessionManager: sessionManager, realm: realm), makeCookie: nil)
    }
}

extension Droplet {
    
    static var instance: Droplet?
    
    internal static func create() -> Droplet {

        let drop = Droplet(availableMiddleware: ["sessions" : SessionsMiddleware.createSessionsMiddleware(),
                                                 "auth" : AuthMiddleware<User>.createAuthMiddleware(),
                                                 "protect" : ProtectMiddleware.createProtectionMiddleware()],
                           preparations: [Box.self, Review.self, Vendor.self, Category.self, Picture.self, Order.self, Shipping.self, Subscription.self,
                                      Pivot<Box, Category>.self, User.self, Session.self, FeaturedBox.self],
                           providers: [VaporMySQL.Provider.self])
        
        Droplet.instance = drop
        return drop
    }
    
    internal func protect() -> ProtectMiddleware {
        return availableMiddleware["protect"] as! ProtectMiddleware
    }
}
