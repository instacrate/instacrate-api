//
//  AuthCollection.swift
//  subber-api
//
//  Created by Hakon Hanesand on 10/10/16.
//
//

import Foundation
import Vapor
import HTTP
import Routing
import JSON
import Auth

final class AuthCollection : RouteCollection, EmptyInitializable {
    
    init () {}
    
    typealias Wrapped = HTTP.Responder
    
    func build<Builder : RouteBuilder>(_ builder: Builder) where Builder.Value == Responder {
        
        builder.group("auth") { auth in
            
            auth.post("login") { request in
                guard let credentials = request.auth.header?.basic else {
                    throw Abort.badRequest
                }
                
                try request.auth.login(credentials)
                
                if let _ = try? request.subject() {
                    return "OK"
                } else {
                    throw AuthError.invalidBasicAuthorization
                }
            }
            
            auth.post("signup") { request in
                return ""
            }
        }
    }
}
