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
            let stripeData = try Stripe.information(forUser: customer)
            customerNode["stripe"] = stripeData.makeNode()
        }
        
        if let shouldIncludeShippingAddresses = request.query?["shipping"]?.bool, shouldIncludeShippingAddresses {
            let shipping = try customer.shippingAddresses().all()
            customerNode["shipping"] = try shipping.makeNode()
        }

        return try customerNode.makeJSON()
    }
    
    func create(_ request: Request) throws -> ResponseRepresentable {
        if let token = request.query?["token"]?.string {
            var customer = try request.customer()
            return try associate(token: token, withCustomer: &customer)
        }
        
        var user = try Customer(json: request.json())
        try user.save()
        return try Response(status: .created, json: user.makeJSON())
    }
    
    private func associate(token: String, withCustomer customer: inout Customer) throws -> ResponseRepresentable {
        if customer.stripe_id != nil {
            _ = try Stripe.associate(paymentSource: token, withUser: customer)
            return Response(status: .noContent)
        } else {
            let id = try Stripe.createStripeCustomer(forUser: &customer, withPaymentSource: token)
            return try Response(status: .created, json: JSON(node: ["id" : id]))
        }
    }
}

extension CustomerController: ResourceRepresentable {

    func makeResource() -> Resource<Customer> {
        return Resource(
            index: detail
        )
    }
}
