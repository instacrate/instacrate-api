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

enum OrderTimeRange: String, TypesafeOptionsParameter, QueryModifiable {

    case day
    case week
    case month

    static var key = "period"
    static var values = [OrderTimeRange.day.rawValue, OrderTimeRange.week.rawValue, OrderTimeRange.month.rawValue]

    static var defaultValue: OrderTimeRange? = .day

    func apply<T : Entity>(_ query: Query<T>) throws -> Query<T> {
        switch self {
        case .month:
            let date = Date()

            let calendar = Calendar.current

            guard let startOfMonth = calendar.date(byAdding: .month, value: -1, to: date) else {
                throw Abort.serverError
            }

            try query.filter("date", .greaterThanOrEquals, startOfMonth)
            try query.filter("date", .lessThanOrEquals, date)
            
            return query

        case .week:
            let date = Date()
            let calendar = Calendar.current

            guard let startOfWeek = calendar.date(byAdding: .weekOfMonth, value: -1, to: date) else {
                throw Abort.serverError
            }

            try query.filter("date", .greaterThanOrEquals, startOfWeek)
            try query.filter("date", .lessThanOrEquals, date)

            return query

        case .day:
            let date = Date()
            let calendar = Calendar.current

            guard let startDay = calendar.date(byAdding: .day, value: -1, to: date) else {
                throw Abort.serverError
            }

            try query.filter("date", .greaterThanOrEquals, startDay)
            try query.filter("date", .lessThanOrEquals, date)

            return query
        }
    }
}

extension Model {
    
    static func find(id _id: NodeRepresentable?) throws -> Self? {
        guard let id = _id else {
            return nil
        }

        return try find(id as NodeRepresentable)
    }
}

extension Order {

    static func orders(for customer: Customer, with range: OrderTimeRange? = nil, fulfilled: Bool? = nil, for box: Box? = nil) throws -> [Order] {
        var query = try Order.query().union(Subscription.self).filter(Subscription.self, "customer_id", customer.id!)

        if let box = box {
            query = try query.filter(Subscription.self, "box_id", box.id!)
        }

        if let fulfilled = fulfilled {
            query = try query.filter("fulfilled", fulfilled)
        }

        return try query.apply(range).all()
    }

    static func orders(for vendor: Vendor, with range: OrderTimeRange? = nil, fulfilled: Bool? = nil, for box: Box? = nil) throws -> [Order] {
        var query = try Order.query().filter("vendor_id", vendor.id!).union(Vendor.self, localKey: "vendor_id", foreignKey: "id")

        if let box = box {
            query = try query.filter(Subscription.self, "box_id", box.id!)
        }

        if let fulfilled = fulfilled {
            query = try query.filter("fulfilled", fulfilled)
        }

        return try query.apply(range).all()
    }

    static func orders(for request: Request, with range: OrderTimeRange? = nil, fulfilled: Bool? = nil, for box: Box? = nil) throws -> [Order] {
        switch request.sessionType {
        case .vendor:
            return try orders(for: request.vendor(), with: range, fulfilled: fulfilled, for: box)
        case .customer:
            return try orders(for: request.customer(), with: range, fulfilled: fulfilled, for: box)
        case .none:
            throw Abort.custom(status: .forbidden, message: "You must be logged in.")
        }
    }
}

final class OrderController: ResourceRepresentable {
    
    func index(_ request: Request) throws -> ResponseRepresentable {

        let period = try? request.extract() as OrderTimeRange
        let fulfilled = request.query?["fulfilled"]?.bool

        return try Order.orders(for: request, with: period, fulfilled: fulfilled).makeJSON()
    }
    
    func create(_ request: Request) throws -> ResponseRepresentable {
        var order: Order = try request.extractModel()
        try order.save()
        return order
    }

    func delete(_ request: Request, order: Order) throws -> ResponseRepresentable {
        try order.delete()
        return Response(status: .noContent)
    }
    
    func modify(_ request: Request, order: Order) throws -> ResponseRepresentable {
        var order: Order = try request.patchModel(order)
        try order.save()
        return try Response(status: .ok, json: order.makeJSON())
    }
    
    func makeResource() -> Resource<Order> {
        return Resource(
            index: index,
            store: create,
            modify: modify,
            destroy: delete
        )
    }
}
