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

final class AuthenticationController {
    
    func login(_ request: Request) throws -> ResponseRepresentable {
        
        let type = try SessionType(node: request.query?["type"])
        
        guard let credentials = request.auth.header?.usernamePassword else {
            throw Abort.badRequest
        }
        
        switch type {
        case .user:
            try request.userSubject().login(credentials: credentials, persist: true)
        case .vendor:
            try request.vendorSubject().login(credentials: credentials, persist: true)
        }
        
        let modelSubject: Model = type == .user ? try request.customer() : try request.vendor()
        return try Response(status: .ok, json: modelSubject.makeJSON())
    }
}
