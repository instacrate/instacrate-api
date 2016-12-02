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

extension Status {
    
    var isSuccessfulStatus: Bool {
        return statusCode > 199 && statusCode < 300
    }
    
    var description: String {
        return "\(isSuccessfulStatus ? "Success" : "Failure") - \(statusCode) : \(reasonPhrase)"
    }
}

class LoggingMiddleware: Middleware {
    
    func respond(to request: Request, chainingTo next: Responder) throws -> Response {
        
        drop.console.info("here1")
        let response: Response = try next.respond(to: request)
        drop.console.info("here2")
        log(request, response: response)
        drop.console.info("here3")
        return response
    }
    
    func log(_ request: Request, response: Response) {
        
        let failure = { (string: String?) in
            drop.console.error(string ?? "")
        }
        
        let info = { (string: String?) in
            drop.console.info(string ?? "")
        }
        
        let logger = response.status.isSuccessfulStatus ? info : failure
        
        logger("")
        logger("Request")
        logger("URL : \(request.uri)")
        logger("Headers : \(request.headers.description)")
        logger("Response - \(response.status.description)")
        logger("")
    }
}
