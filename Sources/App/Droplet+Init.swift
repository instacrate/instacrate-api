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

class CookieLogger: Middleware {
    
    func respond(to request: Request, chainingTo next: Responder) throws -> Response {
        
        drop.console.info("request \(request.description)", newLine: true)
        
        if request.cookies.array.count > 0 {
            drop.console.info("cookies \(request.cookies)", newLine: true)
        }

        let response = try next.respond(to: request)
        
        if response.status.statusCode > 299 || response.status.statusCode < 200 {
            drop.console.info(response.description, newLine: true)
        }
        
        return response
    }
}

extension Droplet {
    
    static var instance: Droplet?
    
    internal static func create() -> Droplet {

        let drop = Droplet(availableMiddleware: ["sessions" : SessionsMiddleware.createSessionsMiddleware(),
                                                 "auth" : AuthMiddleware<User>.createAuthMiddleware(),
                                                 "protect" : ProtectMiddleware.createProtectionMiddleware(),
                                                 "logger" : CookieLogger()],
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
