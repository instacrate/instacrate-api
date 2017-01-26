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
    
    func complete(subscription: inout Subscription) throws {
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
        
        let plan = try box.fetchConnectPlan(for: vendor)
        let stripeCustomer = try vendor.fetchConnectAccount(for: customer, with: subscription.payment)
        
        guard let secret = vendor.keys?.secret else {
            throw Abort.custom(status: .internalServerError, message: "missing publishable key")
        }
        
        let metadata = createMetadataArray(fromModels: [address, customer, vendor, subscription, box])
        let sub = try Stripe.shared.subscribe(user: stripeCustomer, to: plan, oneTime: false, cut: vendor.cut, metadata: metadata, under: secret)
        
        subscription.sub_id = sub.id
        try subscription.save()
    }
}
