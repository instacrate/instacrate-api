//
//  ModificationCollection.swift
//  subber-api
//
//  Created by Hakon Hanesand on 10/23/16.
//
//

import Foundation
import Vapor
import HTTP
import Routing
import JSON
import Auth
import Fluent

final class ModificaionCollection : RouteCollection, EmptyInitializable {
    
    init () {}
    
    typealias Wrapped = HTTP.Responder
    
    private let tables: [String : Model.Type] = ["\(Vendor.self)" : Vendor.self]
    
    func build<Builder : RouteBuilder>(_ builder: Builder) where Builder.Value == Responder {
        
        builder.grouped(drop.protect()).group("modify") { modify in
            
            modify.get(String.self, Int.self, Int.self) { request, table, id, state in
                guard let json = try? request.json() else {
                    throw Abort.custom(status: .badRequest, message: "Missing or malformed json in request body.")
                }
                
                guard let type = self.tables[table] else {
                    throw Abort.custom(status: .badRequest, message: "Table \(table) is not allowed, allowed values are \(self.tables.keys.values)")
                }
                
                switch type {
                case let type as Vendor.Type:
                    guard let vendor = try type.init(from: "\(id)") else {
                        throw Abort.custom(status: .badRequest, message: "Unable to find vendor for id \(id)")
                    }
                    
                    guard let state = ApplicationState(rawValue: id) else {
                        throw Abort.custom(status: .badRequest, message: "Bad state value passed in.")
                    }
                    
                    try vendor.update(toState: state, withJSON: json)

                default:
                    throw Abort.custom(status: .badRequest, message: "Table \(table) is not allowed, allowed values are \(self.tables.keys.values)")
                }
                
                return Response(status: .ok)
            }
        }
    }
}
