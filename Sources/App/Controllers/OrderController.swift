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

extension Model {
    
    static func find(id _id: NodeRepresentable?) throws -> Self? {
        guard let id = _id else {
            return nil
        }

        return try find(id: id)
    }
}

final class OrderController: ResourceRepresentable {
    
    func index(_ request: Request) throws -> ResponseRepresentable {
        
        let vendor = try request.vendor()
        let query = try Order.query().filter("vendor_id", vendor.id!).union(Vendor.self, localKey: "vendor_id", foreignKey: "id")
        
        if request.query?["outstanding"]?.bool ?? false {
            try query.filter("fulfilled", true)
        }
        
        return try query.all().makeJSON()
    }
    
    func create(_ request: Request) throws -> ResponseRepresentable {
        var box = try Box(json: request.json())
        try box.save()
        return try Response(status: .created, json: box.makeJSON())
    }
    
    func makeResource() -> Resource<Order> {
        return Resource(
            index: index,
            store: create
        )
    }
}
