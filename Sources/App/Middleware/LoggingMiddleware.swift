//
//  LoggingMiddleware.swift
//  subber-api
//
//  Created by Hakon Hanesand on 11/21/16.
//
//

import Foundation
import Vapor
import HTTP

class LoggingMiddleware: Middleware {
    
    func respond(to request: Request, chainingTo next: Responder) throws -> Response {
        
        let response = try next.respond(to: request)
        log(request, withResponse: response)
        return response
    }
    
    func log(_ request: Request, withResponse response: Response?) {
        
        if let response = response {
            
            drop.console.info()
            drop.console.info("URL : \(request.uri)")
            drop.console.info("Headers : \(request.headers.description)")
            
            if response.status.statusCode >= 200 && response.status.statusCode < 300 {
                drop.console.info("Success - \(response.status.statusCode) \(response.status.reasonPhrase)")
                return
            }
            
            drop.console.info()
            
            if request.uri.path.contains("png") {
                drop.console.error()
                drop.console.error("File not found : \(request.uri.path)")
                drop.console.error()
                return
            }
            
            if response.status == .notFound || response.status.statusCode == 404 {
                drop.console.error()
                drop.console.error("Page not found : \(request.uri.path)")
                drop.console.error()
                return
            }

            drop.console.error()
            drop.console.error(request.description)

            drop.console.error()

            if response.json != nil {
                drop.console.error(response.description)
            } else {
                drop.console.error("Response")
                drop.console.error("\(response.status.statusCode) - \(response.status.reasonPhrase)")
                drop.console.error(response.headers.description)
            }

            drop.console.error()
            


        } else {
            drop.console.error()
            drop.console.error(request.description)
            drop.console.error()
        }
    }
}
