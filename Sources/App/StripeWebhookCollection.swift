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

enum Action: String {

    case updated
    case deleted
    case created
}

enum StripeResource: String {

    case account
}

func parseEvent(fromRequest request: Request) throws -> (StripeResource, Action) {
    let json = try request.json()

    guard let eventType = json["type"]?.string else {
        throw Abort.custom(status: .badRequest, message: "Event type not found.")
    }

    drop.console.info("event type \(eventType)")

    let components = eventType.components(separatedBy: ".")

    drop.console.info("components \(components)")

    let _resource = components[0..<components.count - 1].joined(separator: ".").lowercased()
    let _action = components[components.count - 1].lowercased()

    guard let resource = StripeResource(rawValue: _resource), let action = Action(rawValue: _action) else {
        throw Abort.custom(status: .noContent, message: "Unsupported event type.")
    }

    drop.console.info("resource \(resource)")
    drop.console.info("action \(action)")

    return (resource, action)
}

class StripeWebhookCollection: RouteCollection {

    static let shared = StripeWebhookCollection()

    fileprivate init() {}

    typealias Wrapped = HTTP.Responder

    fileprivate var webhookHandlers: [StripeResource : [Action : [(StripeResource, Action, Request) throws -> (Response)]]] = [:]

    func registerHandler(forResource resource: StripeResource, action: Action, handler: @escaping (StripeResource, Action, Request) throws -> Response) {

        var resourceHanderGroup = webhookHandlers[resource] ?? [:]
        var actionHandlerGroup = resourceHanderGroup[action] ?? []

        actionHandlerGroup.append(handler)

        resourceHanderGroup[action] = actionHandlerGroup
        webhookHandlers[resource] = resourceHanderGroup

        drop.console.info("Added handler for \(resource.rawValue).\(action.rawValue)")
    }

    func build<B: RouteBuilder>(_ builder: B) where B.Value == Wrapped {

        builder.grouped("stripe").group("webhook") { webhook in

            webhook.post() { request in
                let (resource, action) = try parseEvent(fromRequest: request)

                print(self.webhookHandlers)

                guard let handler = self.webhookHandlers[resource]?[action] else {
                    return try Response(status: .ok, json: Node(node: ["message" : "Not implemented"]).makeJSON())
                }

                drop.console.info("Forwarding \(resource.rawValue).\(action.rawValue) to registered handler.")
                return try handler(resource, action, request)
            }
        }
    }
}
