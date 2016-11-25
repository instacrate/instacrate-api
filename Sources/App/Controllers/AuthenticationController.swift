//
//  AuthenticationController.swift
//  subber-api
//
//  Created by Hakon Hanesand on 11/15/16.
//
//

import Foundation
import Vapor
import HTTP
import Turnstile
import Auth
import Fluent

final class AuthenticationController: ResourceRepresentable {
    
    func login(_ request: Request) throws -> ResponseRepresentable {

        let type = try request.extract() as SessionType
        
        guard let credentials = request.auth.header?.usernamePassword else {
            throw AuthError.noAuthorizationHeader
        }
        
        switch type {
        case .customer:
            try request.userSubject().login(credentials: credentials, persist: true)
        case .vendor:
            try request.vendorSubject().login(credentials: credentials, persist: true)
        case .none:
            throw Abort.custom(status: .badRequest, message: "Can not log in with a session type of none.")
        }
        
        let modelSubject: JSONConvertible = type == .customer ? try request.customer() : try request.vendor()
        return try Response(status: .ok, json: modelSubject.makeJSON())
    }
    
    func makeResource() -> Resource<String> {
        return Resource(
            store: login
        )
    }
}

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
    
    var sessionType: SessionType {
        return (try? customer()) != nil ? .customer : .vendor
    }
    
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
