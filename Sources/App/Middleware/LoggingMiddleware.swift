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
        
        let response: Response!
        
        do {
            response = try next.respond(to: request)
        } catch {
            log(request, error: error)
            return try Response(status: .internalServerError, json: Node(node: ["error" : "true", "message" : "Internal server error... Underlying error \(error)"]).makeJSON())
        }
        
        log(request, response: response)
        
        return response
    }
    
    func log(_ request: Request, response: Response? = nil, error: Error? = nil) {
        
        let failure = { (string: String?) in
            drop.console.error(string ?? "")
        }
        
        let info = { (string: String?) in
            drop.console.info(string ?? "")
        }
        
        let log = error == nil ? info : failure
        
        if let multipart = request.multipart, multipart.count > 0 {
            log("")
            log("Request - Multipart Upload - Hiding request body due to large size")
            log("URL : \(request.uri)")
            log("Headers : \(request.headers.description)")
            log("")
        } else {
            log("")
            log(request.description)
            log("")
        }
        
        if let response = response, request.uri.path.contains("png") {
            
            log("")
            log("Response - \(response.status.description)")
            log("URL : \(request.uri)")
            log("Headers : \(request.headers.description)")
            log("")
            
        } else if let response = response {
            log("")
            log(response.description)
            log("")
        } else {
            log("")
            log("No response.")
            log("")
        }
        
        if let error = error {
            
            log("")
            log("Error \(error)")
            log("")
        }
    }
}
