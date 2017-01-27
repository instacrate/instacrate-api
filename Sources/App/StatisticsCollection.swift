//
//  StatisticsCollection.swift
//  subber-api
//
//  Created by Hakon Hanesand on 1/13/17.
//
//

import Foundation
import Vapor
import HTTP
import Routing

class StatisticsCollection: RouteCollection, EmptyInitializable {

    required init() { }

    typealias Wrapped = HTTP.Responder

    func build<B: RouteBuilder>(_ builder: B) where B.Value == Wrapped {

        builder.group("stats") { stats in

            stats.group("sales") { sales in

                sales.get() { request in
                    let range = try? request.extract() as OrderTimeRange
                    let fulfilled = request.query?["fulfilled"]?.bool

                    let orders = try Order.orders(for: request, with: range, fulfilled: fulfilled).all()
                    let revenue = try orders.map { try $0.box().get()?.price ?? 0 }.sum()
                    let unfullfilled = orders.filter { !$0.fulfilled }

                    return try Node([
                        "revenue" : .number(.double(revenue)),
                        "outstandingOrders" : .number(.int(unfullfilled.count)),
                        "totalBoxesSold" : .number(.int(orders.count))
                    ] as [String : Node]).makeJSON()
                }

                sales.get("box", Box.self) { request, box in
                    let range = try? request.extract() as OrderTimeRange
                    let fulfilled = request.query?["fulfilled"]?.bool

                    let orders = try Order.orders(for: request, with: range, fulfilled: fulfilled, for: box).all()
                    let revenue = try orders.map { try $0.box().get()?.price ?? 0 }.sum()
                    let unfullfilled = orders.filter { !$0.fulfilled }

                    return try Node([
                        "boxRevenue" : .number(.double(revenue)),
                        "outstandingBoxOrders" : .number(.int(unfullfilled.count)),
                        "numberSold" : .number(.int(orders.count))
                    ] as [String : Node]).makeJSON()
                }
            }

            stats.group("visitors") { visitors in

                visitors.get("vendor") { request in
                    throw Abort.custom(status: .notImplemented, message: "Not implemented")
                }

                visitors.get("box", Box.self) { request in
                    throw Abort.custom(status: .notImplemented, message: "Not implemented")
                }
            }
        }
    }
}
