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
import FluentMySQL

final class ShippingController: ResourceRepresentable {

    func index(_ request: Request) throws -> ResponseRepresentable {
        let customer = try request.customer()
        return try customer.shippingAddresses().all().makeJSON()
    }

    func create(_ request: Request) throws -> ResponseRepresentable {
        var customer = try request.customer()
        let node = try request.json().node.add(name: "customer_id", node: customer.id)
        
        var shipping = try Shipping(node: node)

        if let defaultShipping = customer.defaultShipping, defaultShipping == .null || customer.defaultShipping == nil {

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

        if shipping.customer_id != customer.id {
            throw Abort.custom(status: .forbidden, message: "Can not modify another user's shipping.")
        }

        if shipping.isDefault {
            if var next = try customer.defaultShippingAddress().filter("id", .notEquals, shipping.id!).first() {
                next.isDefault = true
                customer.defaultShipping = next.id

                try next.save()
                try customer.save()
            }
        }

        try shipping.delete()
        return Response(status: .noContent)
    }
    
    func modify(_ request: Request, _shipping: Shipping) throws -> ResponseRepresentable {
        var shipping = _shipping
        var customer = try request.customer()
        
        guard shipping.customer_id == customer.id else {
            throw Abort.custom(status: .badRequest, message: "Can not modify another user's shipping address.")
        }
        
        if let isDefault = request.query?["default"]?.bool, isDefault {
            if let oldDefaultShippingId = customer.defaultShipping, var oldShipping = try Shipping.find(oldDefaultShippingId) {
                oldShipping.isDefault = false
                try oldShipping.save()
            }
            
            shipping.isDefault = true
            customer.defaultShipping = shipping.id
            
            try shipping.save()
            try customer.save()
            
            return Response(status: .noContent)
        }
        
        throw Abort.custom(status: .badRequest, message: "Nothing to be done with current request.")
    }
    
    func makeResource() -> Resource<Shipping> {
        return Resource(
            index: index,
            store: create,
            modify: modify,
            destroy: delete
        )
    }
}
