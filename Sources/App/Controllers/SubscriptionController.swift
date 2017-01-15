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

final class SubscriptionController: ResourceRepresentable {
    
    func index(_ request: Request) throws -> ResponseRepresentable {
        let session = request.sessionType

        var query: Query<Subscription>

        switch session {
        case .vendor:
            let vendor = try request.vendor()
            let box_ids = try vendor.boxes().all().map { $0.id! }
            query = try Subscription.query().filter("box_id", .in, box_ids)

        case .customer:
            let customer = try request.customer()
            query = try Subscription.query().filter("customer_id", customer.id!)

        case .none:
            throw Abort.custom(status: .forbidden, message: "You must be logged in as either a vendor or customer.")
        }

        let format = try request.extract() as Subscription.Format
        return try format.apply(on: query.all()).makeJSON()
    }
    
    func create(_ request: Request) throws -> ResponseRepresentable {
        let customer = try request.customer()

        let node = try request.json().node.add(name: "customer_id", node: customer.id)
        var sub = try Subscription(node: node)

        guard let address = try sub.address().get(), try address.customer_id == request.customer().id else {
            throw Abort.custom(status: .forbidden, message: "Logged in user does not own shipping address.")
        }
        
        guard var box = try sub.box().get() else {
            throw Abort.custom(status: .badRequest, message: "Invalid box id on subscription json")
        }
        
        if box.plan_id == nil {
            let plan = try Stripe.shared.createPlan(with: box.price, name: box.name, interval: .month)
            box.plan_id = plan.id
            try box.save()
        }

        guard let plan_id = box.plan_id else {
            throw Abort.custom(status: .internalServerError, message: "Box did not have plan id after creating one.")
        }

        guard let stripe_id = try request.customer().stripe_id else {
            throw Abort.custom(status: .badRequest, message: "User must have stripe id to subscribe to box.")
        }

        let subscription = try Stripe.shared.subscribe(user: stripe_id, to: plan_id, oneTime: false)
        sub.sub_id = subscription.id
        
        try sub.save()
        return try Response(status: .created, json: sub.makeJSON())
    }
    
    func makeResource() -> Resource<Subscription> {
        return Resource(
            index: index,
            store: create
        )
    }
}
