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

class Logger: Middleware {
    
    func respond(to request: Request, chainingTo next: Responder) throws -> Response {
        
        // Do not print multipart form data resopnses as they are quite verbose
        if !(request.contentType?.contains("multipart/form-data") ?? false) {
            drop.console.info("", newLine: true)
            drop.console.info("\(request.description)", newLine: true)
        }
        
        if request.cookies.array.count > 0 {
            drop.console.info("cookies \(request.cookies)", newLine: true)
        }

        let response = try next.respond(to: request)
        
        // Do not log file requests as they are also quite verbose
        if !request.uri.path.contains("png") {
            drop.console.info("", newLine: true)
            
            if response.status != .notFound {
                drop.console.info(response.description, newLine: true)
            } else {
                drop.console.info("404 not found", newLine: true)
            }
        }
        
        return response
    }
}

extension Droplet {
    
    static var instance: Droplet?
    
    internal static func create() -> Droplet {

        let drop = Droplet(availableMiddleware: ["sessions" : SessionsMiddleware.createSessionsMiddleware(),
                                                 "vendorAuth" : UserAuthMiddleware(),
                                                 "userAuth" : VendorAuthMiddleware(),
                                                 "logger" : Logger()],
                           preparations: [Box.self, Review.self, Vendor.self, Category.self, Picture.self, Order.self, Shipping.self, Subscription.self,
                                      Pivot<Box, Category>.self, Customer.self, Session.self, FeaturedBox.self],
                           providers: [VaporMySQL.Provider.self])
        
        Droplet.instance = drop
        return drop
    }
    
    static let userProtect = UserProtectMiddleware()
    static let vendorProtect = VendorProtectMiddleware()
    
    static func protect(_ type: SessionType) -> Middleware {
        switch type {
        case .user: return userProtect
        case .vendor: return vendorProtect
        }
    }
}
