//
//  ShippingController.swift
//  subber-api
//
//  Created by Hakon Hanesand on 11/12/16.
//
//

import Foundation

import Vapor
import HTTP

final class ShippingController {

    func index(_ request: Request) throws -> ResponseRepresentable {
        let customer = try request.customer()
        return try customer.shippingAddresses().all().makeNode()
    }

    func create(_ request: Request) throws -> ResponseRepresentable {
        var shipping = try Shipping(json: request.json())
        var customer = try request.customer()

        if customer.defaultShipping == nil {

            shipping.isDefault = true
            try shipping.save()
            
            customer.defaultShipping = shipping.id
            try customer.save()

        } else {
            try shipping.save()
        }

        return try Response(status: .created, json: shipping.makeJSON())
    }

    func delete(_ request: Request, shipping: Shipping) throws -> ResponseRepresentable {
        var customer = try request.customer()

        if let def = try customer.defaultShippingAddress().get(), def.id == shipping.id {
            customer.defaultShipping = nil
            try customer.save()
        }

        try shipping.delete()
        return Response(status: .noContent)
    }
}
