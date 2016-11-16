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

        if let shouldIncludeStripeData = request.query?["stripe"]?.bool, shouldIncludeStripeData {
            let stripeData = try Stripe.information(forUser: customer)
            customerNode["stripe"] = stripeData.makeNode()
        }

        return customerNode
    }
}

extension CustomerController: ResourceRepresentable {

    func makeResource() -> Resource<Customer> {
        return Resource(
            index: detail
        )
    }
}
