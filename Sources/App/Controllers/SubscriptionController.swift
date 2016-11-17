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

final class SubscriptionController: ResourceRepresentable {
    
    func index(_ request: Request) throws -> ResponseRepresentable {
        if let vendor = try? request.vendor() {
            let box_ids = try vendor.boxes().all().map { $0.id! }
            let query = try Subscription.query().filter("box_id", .in, box_ids)
            return try query.all().makeJSON()
        }
        
        if let customer = try? request.customer() {
            let query = try Subscription.query().filter("customer_id", customer.id!)
            return try query.all().makeJSON()
        }
        
        return Response(status: .forbidden)
    }
    
    func create(_ request: Request) throws -> ResponseRepresentable {
        var sub = try Subscription(json: request.json())
        
        guard var box = try sub.box().get() else {
            throw Abort.custom(status: .badRequest, message: "Invalid box id on subscription json")
        }
        
        if box.plan_id == nil {
            try Stripe.createPlan(forBox: &box)
        }
        
        precondition(box.plan_id != nil, "Box must have plan id")
        
        sub.sub_id = try Stripe.createSubscription(forUser: request.customer(), forBox: box)
        
        try sub.save()
        return try Response(status: .created, json: sub.makeJSON())
    }
    
    func makeResource() -> Resource<Subscription> {
        return Resource()
    }
}
