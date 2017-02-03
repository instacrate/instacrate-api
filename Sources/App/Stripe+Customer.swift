//
//  Stripe+Customer.swift
//  subber-api
//
//  Created by Hakon Hanesand on 1/22/17.
//
//

import Foundation
import Stripe
import Vapor

func createMetadataArray(fromModels models: [Model?]) -> [String: String] {
    
    let primaryKeys = models.filter { $0?.id != nil }.map { (type(of: $0!).entity, "\($0!.id!.int!)") }
    
    return primaryKeys.reduce([:]) { (dict, element) in
        var dict = dict
        dict[element.0] = element.1
        return dict
    }
}

extension Stripe {
    
    func createStandaloneAccount(for customer: Customer, from source: Token, on account: String) throws -> StripeCustomer {
        guard let customerId = customer.id?.int else {
            throw Abort.custom(status: .internalServerError, message: "Missing customer id for customer. \(customer.prettyString)")
        }
        
        return try Stripe.shared.createNormalAccount(email: customer.email, source: source.id, local_id: customerId, on: account)
    }
    
    func createPlanFor(box: Box, with interval: Interval = .month, on account: String) throws -> Plan {
        return try Stripe.shared.createPlan(with: box.price, name: box.name, interval: interval, on: account)
    }
    
    func complete(subscription: inout Subscription, coupon code: String?) throws {
        guard let box = try subscription.box().first() else {
            throw ModelError.missingLink(from: Subscription.self, to: Box.self, id: subscription.box_id?.int)
        }
        
        guard let vendor = try box.vendor().first() else {
            throw Abort.custom(status: .internalServerError, message: "missing vendor id")
        }
        
        guard let customer = try subscription.customer().first() else {
            throw Abort.custom(status: .internalServerError, message: "missing customer cookie")
        }
        
        guard let address = try subscription.address().first() else {
            throw Abort.custom(status: .internalServerError, message: "missing address id")
        }
        
        guard vendor.stripeAccountId != nil else {
            throw Abort.custom(status: .internalServerError, message: "vendor must sign up for stripe before it can be subscribed to")
        }
        
        let plan = try box.fetchConnectPlan(for: vendor)
        let stripeCustomer = try vendor.fetchConnectAccount(for: customer, with: subscription.payment)
        
        guard let secret = vendor.keys?.secret else {
            throw Abort.custom(status: .internalServerError, message: "missing publishable key")
        }
        
        var cupon: Cupon?
        
        if let cuponCode = code {
            let query = try Cupon.query().filter("code", cuponCode)
            cupon = try query.first()
            subscription.cupon_id = cupon?.id
            
//            guard cupon.customer_id == customer.id else {
//                throw Abort.custom(status: .badRequest, message: "That cupon is invalid for this user. Cupon tied to \(cupon.customer_id ?? 0) while sub is for \(customer.id ?? 0)")
//            }
        }
        
        let metadata = createMetadataArray(fromModels: [address, customer, vendor, subscription, box, cupon])
        let sub = try Stripe.shared.subscribe(user: stripeCustomer, to: plan, oneTime: false, cut: vendor.cut, cupon: cupon?.code, metadata: metadata, under: secret)
        
        subscription.sub_id = sub.id
        try subscription.save()
    }
}
