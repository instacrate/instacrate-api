//
//  UserController.swift
//  subber-api
//
//  Created by Hakon Hanesand on 11/12/16.
//
//

import Foundation
import Vapor
import HTTP

final class CustomerController {

    func detail(_ request: Request) throws -> ResponseRepresentable {
        let customer = try request.customer()
        var customerNode = try customer.makeNode()

        if request.query?["stripe"]?.bool ?? false && customer.stripe_id != nil {
            let stripeData = try Stripe.information(forCustomer: customer)
            customerNode["stripe"] = stripeData.makeNode()
        }
        
        if let shouldIncludeShippingAddresses = request.query?["shipping"]?.bool, shouldIncludeShippingAddresses {
            let shipping = try customer.shippingAddresses().all()
            customerNode["shipping"] = try shipping.makeNode()
        }

        return try customerNode.makeJSON()
    }
    
    func create(_ request: Request) throws -> ResponseRepresentable {
        var user = try Customer(json: request.json())
        try user.save()
        return try Response(status: .created, json: user.makeJSON())
    }
}

extension CustomerController: ResourceRepresentable {

    func makeResource() -> Resource<Customer> {
        return Resource(
            index: detail,
            store: create
        )
    }
}
