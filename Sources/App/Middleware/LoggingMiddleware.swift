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
        
        let response: Response = try next.respond(to: request)
        log(request, response: response)
        return response
    }
    
    func log(_ request: Request, response: Response) {
        
        let failure = { (string: String?) in
            drop.console.error(string ?? "")
        }
        
        let info = { (string: String?) in
            drop.console.info(string ?? "")
        }
        
        let log = response.status.isSuccessfulStatus ? info : failure
        
        log("")
        log("Request")
        log("URL : \(request.uri)")
        log("Headers : \(request.headers.description)")
        log("Response - \(response.status.description)")
        log("")
    }
}
