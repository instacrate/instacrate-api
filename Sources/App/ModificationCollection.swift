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
            
            modify.post(String.self, Int.self) { request, table, id in
                guard let json = try? request.json() else {
                    throw Abort.custom(status: .badRequest, message: "Missing or malformed json in request body.")
                }
                
                guard let type = self.tables[table] else {
                    throw Abort.custom(status: .badRequest, message: "Table \(table) is not allowed, allowed values are \(self.tables.keys.values)")
                }
                
                guard let modifyable = try type.init(from: "\(id)") as? Updateable else {
                    throw Abort.custom(status: .badRequest, message: "Table \(table) is not allowed, allowed values are \(self.tables.keys.values)")
                }
                
                try modifyable.update(withJSON: json)
                return Response(status: .ok)
            }
        }
    }
}
