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

func extractFrom<T: Model>(metadata: Node) throws -> T? {
    return try metadata[T.entity]?.string.flatMap { try T(from: $0) }
}

class StripeWebhookCollection {
    
    static let triggerStrings = ["legal_entity.verification.document",
                                 "legal_entity.additional_owners.0.verification.document",
                                 "legal_entity.additional_owners.1.verification.document",
                                 "legal_entity.additional_owners.2.verification.document",
                                 "legal_entity.additional_owners.3.verification.document"]

    required init() {

        StripeWebhookManager.shared.registerHandler(forResource: .account, action: .updated) { (event) -> Response in
            guard let account = event.data.object as? Account else {
                throw Abort.custom(status: .internalServerError, message: "Failed to parse the account from the account.updated event.")
            }
            
            guard let vendor = try Vendor.find(id: account.metadata["id"]) else {
                Droplet.logger?.error("Stripe account \(account.id) is missing a connected vendor in its metadata.")
                throw Abort.custom(status: .internalServerError, message: "Missing connected vendor for account with id \(account.id)")
            }
            
            vendor.missingFields = account.verification.fields_needed.count > 0
            vendor.needsIdentityUpload = StripeWebhookCollection.triggerStrings.map { account.verification.fields_needed.contains($0) }.reduce(false) { $0 || $1 }
            
            return Response(status: .ok)
        }

        StripeWebhookManager.shared.registerHandler(forResource: .invoice, action: .created) { (event) -> Response in
            
            guard let invoice = event.data.object as? Invoice else {
                throw Abort.custom(status: .internalServerError, message: "Failed to parse the invoice from the invoice.created event.")
            }

            guard let subscription: Subscription = try extractFrom(metadata: invoice.metadata),
                  let vendor: Vendor = try extractFrom(metadata: invoice.metadata),
                  let customer: Customer = try extractFrom(metadata: invoice.metadata),
                  let shipping: Shipping = try extractFrom(metadata: invoice.metadata),
                  let box: Box = try extractFrom(metadata: invoice.metadata)
            else {
                throw Abort.custom(status: .internalServerError, message: "Wrong or missing metadata \(invoice.metadata)")
            }

            var order = Order(with: subscription.id, vendor_id: vendor.id, box_id: box.id, shipping_id: shipping.id, customer_id: customer.id, order_id: invoice.id)
            try order.save()

            let _ = try Stripe.shared.updateInvoiceMetadata(for: order.id!.int!, invoice_id: invoice.id)

            return try Response(status: .ok, json: Node(node: ["status" : "ok"]).makeJSON())
        }
    }
}
