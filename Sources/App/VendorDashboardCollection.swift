//
//  VendorDashboardCollection.swift
//  subber-api
//
//  Created by Hakon Hanesand on 11/10/16.
//
//

import Foundation
import Vapor
import HTTP
import Routing
import JSON
import Auth

final class VendorDashboardCollection : RouteCollection, EmptyInitializable {
    
    init () {}
    
    typealias Wrapped = HTTP.Responder
    
    func build<Builder : RouteBuilder>(_ builder: Builder) where Builder.Value == Responder {
        
        let vendor = builder.grouped("vendor").grouped(Droplet.protect(.vendor))
        
        vendor.get("orders") { request in
            let vendor = try request.vendor()
            
            return ""
        }
        
    }
}
