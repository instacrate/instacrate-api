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
import Turnstile

extension Authorization {
    public var usernamePassword: UsernamePassword? {
        guard let range = header.range(of: "Basic ") else {
            return nil
        }
        
        let authString = header.substring(from: range.upperBound)
        
        let decodedAuthString = authString.base64DecodedString
        guard let separatorRange = decodedAuthString.range(of: ":") else {
            return nil
        }
        
        let username = decodedAuthString.substring(to: separatorRange.lowerBound)
        let password = decodedAuthString.substring(from: separatorRange.upperBound)
        
        return UsernamePassword(username: username, password: password)
    }
}

final class AuthCollection : RouteCollection, EmptyInitializable {
    
    init () {}
    
    typealias Wrapped = HTTP.Responder
    
    func build<Builder : RouteBuilder>(_ builder: Builder) where Builder.Value == Responder {
        
        builder.group("auth") { auth in
            
            auth.post("login") { request in
                guard let credentials = request.auth.header?.usernamePassword else {
                    throw Abort.badRequest
                }
                
                try request.auth.login(credentials)
                
                if let _ = try? request.subject() {
                    return Response(status: .ok)
                } else {
                    throw AuthError.invalidBasicAuthorization
                }
            }
        }
    }
}
