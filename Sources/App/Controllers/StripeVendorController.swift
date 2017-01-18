//
//  StripeVendorController.swift
//  subber-api
//
//  Created by Hakon Hanesand on 12/2/16.
//
//

import Foundation
import Vapor
import HTTP

final class StripeVendorController: ResourceRepresentable {
    
    func create(_ request: Request) throws -> ResponseRepresentable {
        let type = try request.extract() as StripeModel
        
        switch type {
        case .vendor:
            var vendor = try request.vendor()
            let _ = try Stripe.shared.createStripeCustomer(forVendor: &vendor)
        default:
            break
        }
        
        throw Abort.custom(status: .badRequest, message: "Missing or wrong type from query string.")
    }
    
    func makeResource() -> Resource<Vendor> {
        return Resource()
    }
}
