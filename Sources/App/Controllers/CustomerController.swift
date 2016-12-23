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

enum FetchType: String, TypesafeOptionsParameter {

    case stripe
    case shipping

    static let key = "type"
    static let values = [FetchType.stripe.rawValue, FetchType.shipping.rawValue]

    static var defaultValue: FetchType? = nil
}

final class CustomerController {

    func detail(_ request: Request) throws -> ResponseRepresentable {
        let customer = try request.customer()
        var customerNode = try customer.makeNode()

        let options = try request.extract() as [FetchType]

        if options.contains(.stripe) {
            if let card = request.query?["card"]?.string {
                let stripeData = try Stripe.shared.information(forCustomer: customer)
                customerNode["card"] = stripeData.makeNode()[["sources", "data"]]?.nodeArray?.filter { $0["id"]?.string == card }.first
            } else {
                let stripeData = try Stripe.shared.information(forCustomer: customer)
                customerNode["stripe"] = stripeData.makeNode()
            }
        }

        if options.contains(.shipping) {
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
