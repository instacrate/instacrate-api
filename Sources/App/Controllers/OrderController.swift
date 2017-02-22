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

// TODO : Change to how stripe does it by just having one parameter that specifies to and from

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
    
    enum Format: String, TypesafeOptionsParameter {
        case long
        case short
        
        static let key = "format"
        static let values = ["long", "short"]
        static let defaultValue: Format? = .short
        
        func apply(on order: Order) throws -> Node {
            switch self {
            case .long:
                return try createLongView(for: order)
                
            case .short:
                return try createTerseView(for: order)
            }
        }
        
        func apply(on orders: [Order]) throws -> Node {
            
            return try .array(orders.map {
                return try self.apply(on: $0)
            })
        }
    }
}

fileprivate func createTerseView(for order: Order) throws -> Node {
    let customer = try order.customer().first()
    let box = try order.box().first()
    
    return try Node(node: [
        "id" : "\(order.throwableId())",
        "date" : "\(order.date.timeIntervalSince1970)"
    ]).add(objects: [
        "customerName" : customer?.name,
        "boxName" : box?.name,
        "price" : box?.price
    ])
}

fileprivate func createLongView(for order: Order) throws -> Node {
    let customer = try order.customer().first()
    let box = try order.box().first()
    let shipping = try order.shippingAddress().first()
    
    return try Node(node: [
        "id" : "\(order.throwableId())",
        "date" : "\(order.date.timeIntervalSince1970)"
    ]).add(objects: [
        "customerName" : customer?.name,
        "boxName" : box?.name,
        "price" : box?.price,
        "customerEmail" : customer?.email,
        "address" : shipping
    ])
}

extension Order {
    
    // TODO : make sure this works
    
    static func orders(for request: Request) throws -> Query<Order> {
        let type = try request.extract() as SessionType
        
        switch type {
        case .vendor:
            let vendor = try request.vendor()
            return try Order.query().filter("vendor_id", vendor.throwableId())
            
        case .none: fallthrough
        case .customer:
            let customer = try request.customer()
            return try Order.query().filter("customer_id", customer.throwableId())
        }
    }

    static func orders(for request: Request, with range: OrderTimeRange? = nil, fulfilled: Bool? = nil, for box: Box? = nil) throws -> Query<Order> {
        var query = try Order.orders(for: request)

        if let box = box {
            query = try query.filter("box_id", box.throwableId())
        }

        if let fulfilled = fulfilled {
            query = try query.filter("fulfilled", fulfilled)
        }

        return try query.apply(range)
    }
}

final class OrderController: ResourceRepresentable {
    
    func index(_ request: Request) throws -> ResponseRepresentable {

        let period = try? request.extract() as OrderTimeRange
        let fulfilled = request.query?["fulfilled"]?.bool
        let format = try request.extract() as Order.Format

        let orders = try Order.orders(for: request, with: period, fulfilled: fulfilled).all()
        return try format.apply(on: orders).makeJSON()
    }
    
    func create(_ request: Request) throws -> ResponseRepresentable {
        var order: Order = try request.extractModel(injecting: request.customerInjectable())
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
