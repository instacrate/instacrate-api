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
import JSON

extension Status {
    
    var isSuccessfulStatus: Bool {
        return statusCode > 199 && statusCode < 400
    }
    
    var description: String {
        return "\(isSuccessfulStatus ? "Success" : "Failure") - \(statusCode) : \(reasonPhrase)"
    }
}

class LoggingMiddleware: Middleware {
    
    func respond(to request: Request, chainingTo next: Responder) throws -> Response {
    
        let response: Response = try next.respond(to: request)
        try log(request, response: response)
        return response
    }
    
    func log(_ request: Request, response: Response) throws {
        
        let failure = { (string: String?) in
            if let string = string {
                Droplet.logger?.error(string)
            }
        }
        
        let info = { (string: String?) in
            if let string = string {
                Droplet.logger?.info(string)
            }
        }
        
        let logger = response.status.isSuccessfulStatus ? info : failure
        
        logger("")
        logger("Request")
        logger("URL : \(request.uri)")
        logger("Headers : \(request.headers.description)")

        if let json = request.json {
            try logger("JSON : \(String(bytes: json.serialize(prettyPrint: true)))")
        }
        
        logger("Response - \(response.status.description)")
        logger("")
    }
}