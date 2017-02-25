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

extension Shipping {
    
    func shouldAllow(request: Request) throws {
        do {
            try request.has(session: .vendor)
        } catch {
            throw try Abort.custom(status: .forbidden, message: "Method \(request.method) is not allowed on resource Review(\(throwableId())) by this user. Must be logged in as Customer(\(customer_id?.int ?? 0)).")
        }
        
        let customer = try request.customer()
        
        guard try customer.throwableId() == customer_id?.int else {
            throw try Abort.custom(status: .forbidden, message: "This Customer(\(customer.throwableId())) does not have access to resource Shipping(\(throwableId()). Must be logged in as Customer(\(customer_id?.int ?? 0).")
        }
    }
}

final class ShippingController: ResourceRepresentable {

    func index(_ request: Request) throws -> ResponseRepresentable {
        let customer = try request.customer()
        return try customer.shippingAddresses().all().makeJSON()
    }

    func create(_ request: Request) throws -> ResponseRepresentable {
        var customer = try request.customer()
        var shipping: Shipping = try request.extractModel(injecting: request.customerInjectable())
        
        if let defaultShipping = try request.customer().defaultShipping, defaultShipping == .null || defaultShipping == nil {
            shipping.isDefault = true
            try shipping.save()

            customer.defaultShipping = shipping.id
            try customer.save()
        } else {
            try shipping.save()
        }
        
        return shipping
    }

    func delete(_ request: Request, shipping: Shipping) throws -> ResponseRepresentable {
        try shipping.shouldAllow(request: request)
        
        var customer = try request.customer()

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
    
    func modify(_ request: Request, shipping: Shipping) throws -> ResponseRepresentable {
        try shipping.shouldAllow(request: request)
        
        var customer = try request.customer()
        
        guard shipping.customer_id == customer.id else {
            throw Abort.custom(status: .forbidden, message: "Can not modify another user's shipping address.")
        }
        
        var updated: Shipping = try request.patchModel(shipping)
        
        if updated.isDefault && !shipping.isDefault {
            if var previous = try request.customer().defaultShippingAddress().first() {
                previous.isDefault = false
                customer.defaultShipping = updated.id

                try previous.save()
                try customer.save()
            }
        }
        
        try updated.save()
        return updated
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
