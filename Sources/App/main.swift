//
//  Main.swift
//  subber-api
//
//  Created by Hakon Hanesand on 9/26/16.
//
//

import Vapor
import Fluent
import Node
import HTTP
import Turnstile
import Foundation
import Auth
import Stripe

let drop = Droplet.create()

drop.resource("boxes", BoxController())
drop.resource("customers", CustomerController())
drop.resource("shipping", ShippingController())
drop.resource("authentication", AuthenticationController())
drop.resource("categories", CategoryController())
drop.resource("orders", OrderController())
drop.resource("vendors", VendorController())
drop.resource("reviews", ReviewController())
drop.resource("subscriptions", SubscriptionController())
drop.resource("search", SearchController())
drop.resource("images", ImageController())
drop.resource("contracts", ContractController())
drop.resource("logs", LogFileController())

drop.collection(StripeCollection.self)
drop.collection(StripeWebhookManager.shared)

drop.run()
