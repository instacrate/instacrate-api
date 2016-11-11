//
//  ValidationCollection.swift
//  subber-api
//
//  Created by Hakon Hanesand on 10/18/16.
//
//

import Foundation
import Vapor
import HTTP
import Routing
import JSON
import Node
import Fluent

extension Request {
    
}

final class ValidationCollection : RouteCollection, EmptyInitializable {
    
    init () {}
    
    typealias Wrapped = HTTP.Responder
    
    let allowedTables = ["user" : User.self] as [String: Model.Type]
    
    let allowedFields = [String(describing: User.self) : ["email"]] as [String: [String]]
    
    let vendorType = Vendor.self
    let userType = Query<User>.self
    
    func build<Builder : RouteBuilder>(_ builder: Builder) where Builder.Value == Responder {
        
        let available = builder.grouped("validation").grouped("available")
        
        available.get(String.self, String.self, String.self) { request, _table, field, value in
            // TODO : Test if value is vunerable to sql injection
            
            guard let table = self.allowedTables[_table] else {
                throw Abort.custom(status: .badRequest, message: "Table \(_table) is not allowed. Allowed values are \(self.allowedTables.keys)")
            }
            
            if let contains = self.allowedFields["\(table)"]?.contains(field), contains {
                
                let model = try self.runQuery(forKnownType: table, field: field, value: value)
                let status: Status = model == nil ? .ok : .conflict
                
                return Response(status: status)
            } else {
                throw Abort.custom(status: .badRequest, message: "Field \(field) for table \(table) is not allowed. Allowed values are \(self.allowedFields[String(describing: table)])")
            }
        }
    }
    
    private func runQuery(forKnownType type: Model.Type, field: String, value: String) throws -> Model? {
        switch type {
        case let table as Vendor.Type:
            return try table.query().filter(field, value).first()
        case let table as User.Type:
            return try table.query().filter(field, value).first()
        default:
            throw Abort.custom(status: .internalServerError, message: "Unkown type in runQuery function : \(type).")
        }
    }
}
