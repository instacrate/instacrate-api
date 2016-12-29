//
//  OrderController.swift
//  subber-api
//
//  Created by Hakon Hanesand on 11/15/16.
//
//

import Foundation
import HTTP
import Vapor
import Fluent

extension Model {
    
    static func find(id _id: NodeRepresentable?) throws -> Self? {
        guard let id = _id else {
            return nil
        }

        return try find(id as NodeRepresentable)
    }
}

extension Query {
    
    static func orderQuery(for customer: Customer) throws -> Query<Order> {
        return try Order.query().union(Subscription.self).filter(Subscription.self, "customer_id", customer.id!)
    }
    
    static func orderQuery(for vendor: Vendor) throws -> Query<Order> {
        return try Order.query().filter("vendor_id", vendor.id!).union(Vendor.self, localKey: "vendor_id", foreignKey: "id")
    }
}

final class OrderController: ResourceRepresentable {
    
    func index(_ request: Request) throws -> ResponseRepresentable {
        
        var query: Query<Order>
        
        switch request.sessionType {
        case .vendor:
            query = try Query<Vendor>.orderQuery(for: request.vendor())
        case .customer:
            query = try Query<Customer>.orderQuery(for: request.customer())
        case .none:
            throw Abort.custom(status: .forbidden, message: "Must be logged in to see orders.");
        }
        
        if let fulfilled = request.query?["fulfilled"]?.bool {
            try query.filter("fulfilled", fulfilled)
        }
        
        return try query.all().makeJSON()
    }
    
    func create(_ request: Request) throws -> ResponseRepresentable {
        var box = try Order(json: request.json())
        try box.save()
        return try Response(status: .created, json: box.makeJSON())
    }

    func delete(_ request: Request, order: Order) throws -> ResponseRepresentable {
        try order.delete()
        return Response(status: .noContent)
    }
    
    func makeResource() -> Resource<Order> {
        return Resource(
            index: index,
            store: create,
            destroy: delete
        )
    }
}
