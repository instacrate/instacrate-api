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

class Logger: Middleware {
    
    func respond(to request: Request, chainingTo next: Responder) throws -> Response {
        
        let response: Response!
        
        do {
            response = try next.respond(to: request)
        } catch {
            log(request, withResponse: nil)
            throw Abort.custom(status: .internalServerError, message: "Internal server error... Underlying error \(error)")
        }
        
        log(request, withResponse: response)
        
        return response
    }
    
    func log(_ request: Request, withResponse response: Response?) {
        
        if let response = response {
            
            drop.console.info("URL : \(request.uri)")
            drop.console.info("Headers : \(request.headers.description)")
            
            drop.console.info("")
            
            if response.status.statusCode >= 200 || response.status.statusCode < 300 {
                drop.console.info("Success - \(response.status.statusCode) \(response.status.reasonPhrase)")
                return
            }
            
            if request.uri.path.contains("png") {
                drop.console.error("")
                drop.console.error("File not found : \(request.uri.path)")
                drop.console.error("")
                return
            }
            
            drop.console.error(request.description)
            drop.console.error()
            drop.console.error(response.description)
        } else {
            drop.console.error(request.description)
        }
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
        case .customer: return userProtect
        case .vendor: return vendorProtect
        case .none: return userProtect
        }
    }
}
