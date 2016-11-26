//
//  StripeController.swift
//  subber-api
//
//  Created by Hakon Hanesand on 11/21/16.
//
//

import Foundation
import Vapor
import HTTP

enum StripeModel: String, TypesafeOptionsParameter {
    case customer
    
    static let key = "type"
    static let values = [StripeModel.customer.rawValue]
    static let defaultValue: StripeModel? = nil
}

extension Request {
    
    var sourceToken: String? {
        return query?["source"]?.string
    }
}

final class StripeController: ResourceRepresentable {

    init() {
        StripeWebhookCollection.shared.registerHandler(forResource: .account, action: .updated) { (resource, action, request) throws -> Response in
            return try Response(status: .noContent)
        }
    }
    
    func create(_ request: Request) throws -> ResponseRepresentable {
        let type = try request.extract() as StripeModel
        
        switch type {
        case .customer:
            var customer = try request.customer()
            
            if let token = request.sourceToken {
                try Stripe.shared.createStripeCustomer(forUser: &customer, withPaymentSource: token)
                return try Response(status: .created, json: customer.makeJSON())
            }
        }
        
        return Response(status: .noContent)
    }
    
    func modify(_ request: Request, customer: Customer) throws -> ResponseRepresentable {
        if let token = request.sourceToken {
            let customer = try request.customer()

            guard customer.stripe_id != nil else { throw Abort.custom(status: .badRequest, message: "Must create stripe user before associating.") }
        
            try Stripe.shared.associate(paymentSource: token, withCustomer: customer)
            return Response(status: .noContent)
        }
        
        return Response(status: .notImplemented)
    }
    
    func makeResource() -> Resource<Customer> {
        return Resource(
            store: create,
            modify: modify
        )
    }
}
