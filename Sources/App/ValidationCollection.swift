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
        
        builder.group("available") { available in
            
            available.group("customer") { customer in
                
                customer.get("email", String.self) { request, email in
                    let customers = try Customer.query().filter("email", email).count()
                    return Response(status: customers > 0 ? .conflict : .ok)
                }
            }
            
            available.group("vendor") { vendor in
                
                vendor.get("contactEmail", String.self) { request, email in
                    let vendors = try Vendor.query().filter("contactEmail", email).count()
                    return Response(status: vendors.count > 0 ? .conflict : .ok)
                }
                
                vendor.get("username", String.self) { request, username in
                    let vendors = try Vendor.query().filter("username", username).count()
                    return Response(status: vendors.count > 0 ? .conflict : .ok)
                }
            }
        }
    }
}
