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

let drop = Droplet.create()

drop.resource("boxes", BoxController())
drop.resource("customers", CustomerController())
drop.resource("shipping", ShippingController())
drop.resource("authentication", AuthenticationController())
drop.resource("category", CategoryController())
drop.resource("order", OrderController())
drop.resource("vendor", VendorController())
drop.resource("review", ReviewController())
drop.resource("subscription", SubscriptionController())

drop.run()
