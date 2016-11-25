//
//  StripeWebhookCollection.swift
//  subber-api
//
//  Created by Hakon Hanesand on 11/25/16.
//
//

import Foundation
import HTTP
import Routing
import Vapor

class V1Collection: RouteCollection {

    typealias Wrapped = HTTP.Responder

    func build<B: RouteBuilder>(_ builder: B) where B.Value == Wrapped {

        builder.group("webhook") { webhook in

            webhook.post() { request in
                drop.console.info(request.description)
                return Response(status: .ok)
            }
        }
    }
}
