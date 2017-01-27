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

func createMetadataArray(fromModels models: [Model]) -> [String: String] {

    let primaryKeys = models.filter { $0.id != nil }.map { (type(of: $0).entity, "\($0.id!.int!)") }

    return primaryKeys.reduce([:]) { (dict, element) in
        var dict = dict
        dict[element.0] = element.1
        return dict
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
            throw Abort.custom(status: .forbidden, message: "You must be logged in as either a vendor or customer.")
        }

        let format = try request.extract() as Subscription.Format
        return try format.apply(on: query.all()).makeJSON()
    }
    
    func create(_ request: Request) throws -> ResponseRepresentable {
        var subscription: Subscription = try request.extractModel(injecting: request.customerInjectable())
        try Stripe.shared.complete(subscription: &subscription)
        return subscription
    }
    
    func modify(_ request: Request, subscription: Subscription) throws -> ResponseRepresentable {
        var subscription: Subscription = try request.patchModel(subscription)
        try subscription.save()
        return try Response(status: .ok, json: subscription.makeJSON())
    }
    
    func makeResource() -> Resource<Subscription> {
        return Resource(
            index: index,
            store: create,
            modify: modify
        )
    }
}
