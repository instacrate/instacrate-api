//
//  Subscription+Definitions.swift
//  subber-api
//
//  Created by Hakon Hanesand on 1/13/17.
//
//

import Foundation
import Node

extension Subscription {

    enum Format: String, Formatter {

        typealias Input = Subscription

        case long
        case short

        static let key = "format"
        static let values = ["long", "short"]
        static let defaultValue: Format? = .short

        func apply(on model: Subscription) throws -> Node {
            switch self {
            case .long:
                return try createLongView(for: model)
            case .short:
                return try createTerseView(for: model)
            }
        }

        func apply(on models: [Subscription]) throws -> Node {

            return try Node.array(models.map { (box: Subscription) -> Node in
                return try self.apply(on: box)
            })
        }
    }
}

fileprivate func createTerseView(for subscription: Subscription) throws -> Node {
    return try subscription.makeNode()
}

fileprivate func createLongView(for subscription: Subscription) throws -> Node {
    let orders = try subscription.orders().all()

    return try subscription.makeNode().add(objects: ["orders" : Node(node: orders)])
}
