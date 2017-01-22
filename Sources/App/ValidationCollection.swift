//
//  ValidationCollection.swift
//  subber-api
//
//  Created by Hakon Hanesand on 1/22/17.
//
//

import Foundation
import HTTP
import Routing
import Vapor

class ValidationCollection: RouteCollection, EmptyInitializable {
    
    required init() { }
    
    typealias Wrapped = HTTP.Responder
    
    func build<B: RouteBuilder>(_ builder: B) where B.Value == Wrapped {
        
        builder.group("customer", "available") { customer in
            
            customer.get("email") { email in
                let customers = try Customer.query().filter("email", email).count()
                return Response(status: customers > 0 ? .conflict : .ok)
            }
        }
        
        builder.group("vendor", "available") { vendor in
            
            vendor.get("contactEmail") { email in
                let vendors = try Vendor.query().filter("contactEmail", email).count()
                return Response(status: vendors.count > 0 ? .conflict : .ok)
            }
            
            vendor.get("username") { username in
                let vendors = try Vendor.query().filter("username", username).count()
                return Response(status: vendors.count > 0 ? .conflict : .ok)
            }
        }
    }
}
