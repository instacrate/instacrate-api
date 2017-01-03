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
    }
}
