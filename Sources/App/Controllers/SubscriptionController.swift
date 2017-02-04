//
//  SubscriptionController.swift
//  subber-api
//
//  Created by Hakon Hanesand on 11/16/16.
//
//

import Foundation
import Vapor
import HTTP
import Stripe
import Fluent

extension Subscription {
    
    func shouldAllow(request: Request) throws {
        switch request.sessionType {
        case .customer:
            let customer = try request.customer()
            guard try customer.throwableId() == customer_id?.int else {
                throw try Abort.custom(status: .forbidden, message: "This Customer(\(customer.throwableId())) does not have access to resource Subscription(\(throwableId()). Must be logged in as Customer(\(customer_id?.int ?? 0).")
            }
            
        case .vendor: fallthrough
        case .none:
            throw try Abort.custom(status: .forbidden, message: "Method \(request.method) is not allowed on resource Subscription(\(throwableId())) by this user. Must be logged in as Customer(\(customer_id?.int ?? 0)).")
        }
    }
}

final class SubscriptionController: ResourceRepresentable {
    
    func index(_ request: Request) throws -> ResponseRepresentable {
        let session = request.sessionType

        var query: Query<Subscription>

        switch session {
        case .vendor:
            let vendor = try request.vendor()
            let box_ids = try vendor.boxes().all().map { try $0.throwableId() }
            query = try Subscription.query().filter("box_id", .in, box_ids)

        case .customer:
            let id = try request.customer().throwableId()
            query = try Subscription.query().filter("customer_id", id)

        case .none:
            throw Abort.custom(status: .forbidden, message: "You must be logged in as either a vendor or customer to fetch subscriptions.")
        }

        let format = try request.extract() as Subscription.Format
        return try format.apply(on: query.all()).makeJSON()
    }
    
    func create(_ request: Request) throws -> ResponseRepresentable {
        let couponCode: String? = try request.json().node.extract("couponCode")
        var subscription: Subscription = try request.extractModel(injecting: request.customerInjectable())
        try Stripe.shared.complete(subscription: &subscription, coupon: couponCode)
        return subscription
    }
    
    func modify(_ request: Request, subscription: Subscription) throws -> ResponseRepresentable {
        try subscription.shouldAllow(request: request)
        
        var subscription: Subscription = try request.patchModel(subscription)
        try subscription.save()
        return try Response(status: .ok, json: subscription.makeJSON())
    }
    
    func delete(_ request: Request, subscription: Subscription) throws -> ResponseRepresentable {
        try subscription.shouldAllow(request: request)
        
        try subscription.delete()
        return Response(status: .noContent)
    }
    
    func makeResource() -> Resource<Subscription> {
        return Resource(
            index: index,
            store: create,
            modify: modify,
            destroy: delete
        )
    }
}
