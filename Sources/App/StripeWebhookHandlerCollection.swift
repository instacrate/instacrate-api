//
//  StripeWebhookHandlerCollection.swift
//  subber-api
//
//  Created by Hakon Hanesand on 1/2/17.
//
//

import Foundation
import HTTP
import Routing
import Vapor
import Stripe

class StripeWebhookCollection {

    required init() {

        StripeWebhookManager.shared.registerHandler(forResource: .account, action: .updated) { (resource, action, request) -> Response in
            return Response(status: .noContent)
        }

        StripeWebhookManager.shared.registerHandler(forResource: .invoice, action: .created) { (resource, action, request) -> Response in
            guard let node = request.json?.makeNode() else {
                throw Abort.custom(status: .badRequest, message: "1")
            }

            guard let customer_id = node["object", "customer"] else {
                throw Abort.custom(status: .badRequest, message: "2")
            }

            guard let subscription_id = node["object", "lines", "data", "id"] else {
                throw Abort.custom(status: .badRequest, message: "3")
            }

            guard let plan_id = node["object", "lines", "data", "plan", "id"] else {
                throw Abort.custom(status: .badRequest, message: "4")
            }

            guard let customer = try Customer.query().filter("stripe_id", customer_id).first() else {
                throw Abort.custom(status: .badRequest, message: "5")
            }

            guard let subscription = try Subscription.query().filter("sub_id", subscription_id).first() else {
                throw Abort.custom(status: .badRequest, message: "6")
            }

            guard let box = try Box.query().filter("plan_id", plan_id).first() else {
                throw Abort.custom(status: .badRequest, message: "7")
            }

            guard let vendor = try box.vendor().first() else {
                throw Abort.custom(status: .badRequest, message: "8")
            }

            guard let shipping = try subscription.address().get() else {
                throw Abort.custom(status: .badRequest, message: "9")
            }

            var order = Order(with: subscription.id, vendor_id: vendor.id, box_id: box.id, shipping_id: shipping.id, customer_id: customer.id)
            try order.save()

            return try Response(status: .ok, json: Node(node: ["status" : "ok"]).makeJSON())
        }

        StripeWebhookManager.shared.registerHandler(forResource: .charge, action: .pending) { (resource, action, request) -> Response in
            return Response(status: .noContent)
        }

        StripeWebhookManager.shared.registerHandler(forResource: .charge, action: .refunded) { (resource, action, request) -> Response in
            return Response(status: .noContent)
        }

        StripeWebhookManager.shared.registerHandler(forResource: .charge, action: .updated) { (resource, action, request) -> Response in
            return Response(status: .noContent)
        }
    }
}
