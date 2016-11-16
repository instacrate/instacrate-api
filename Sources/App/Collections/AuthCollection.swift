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

extension Request {
    
    func customer() throws -> Customer {
        let subject = try userSubject()
        
        guard let details = subject.authDetails else {
            throw AuthError.notAuthenticated
        }
    
        guard let customer = details.account as? Customer else {
            throw AuthError.invalidAccountType
        }
            
        return customer
    }
    
    func vendor() throws -> Vendor {
        let subject = try vendorSubject()
        
        guard let details = subject.authDetails else {
            throw AuthError.notAuthenticated
        }
        
        guard let vendor = details.account as? Vendor else {
            throw AuthError.invalidAccountType
        }
        
        return vendor
    }
}

final class AuthCollection : RouteCollection, EmptyInitializable {
    
    init () {}
    
    typealias Wrapped = HTTP.Responder
    
    func build<Builder : RouteBuilder>(_ builder: Builder) where Builder.Value == Responder {
        
        builder.group("auth") { auth in
            
            auth.post("user", "login") { request in
                guard let credentials = request.auth.header?.usernamePassword else {
                    throw Abort.badRequest
                }
                
                try request.userSubject().login(credentials: credentials, persist: true)
                
                let customer = try request.customer()                
                return try Response(status: .ok, json: customer.makeJSON())
            }
            
            auth.post("vendor", "login") { request in
                guard let credentials = request.auth.header?.usernamePassword else {
                    throw Abort.badRequest
                }
                
                try request.vendorSubject().login(credentials: credentials, persist: true)
                
                let vendor = try request.vendor()
                return try Response(status: .ok, json: vendor.makeJSON())
            }
        }
    }
}
