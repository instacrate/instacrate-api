//
//  BoxPlan.swift
//  subber-api
//
//  Created by Hakon Hanesand on 1/22/17.
//
//

import Foundation
import Vapor
import Fluent

final class BoxPlan: Model, Preparation {
    
    var id: Node?
    var exists: Bool = false
    
    let box_id: Node?
    let vendor_id: Node?
    let plan_id: String
    
    init(box: Box, plan_id: String, vendor: Vendor) throws {
        guard let box_id = box.id else {
            throw Abort.custom(status: .internalServerError, message: "Missing vendor id for VendorCustomer link.")
        }
        
        guard let vendor_id = vendor.id else {
            throw Abort.custom(status: .internalServerError, message: "Missing vendor id for VendorCustomer link.")
        }
        
        self.vendor_id = vendor_id
        self.box_id = box_id
        self.plan_id = plan_id
    }
    
    init(node: Node, in context: Context) throws {
        id = node["id"]
        plan_id = try node.extract("plan_id")
        box_id = try node.extract("box_id")
        vendor_id = try node.extract("vendor_id")
    }
    
    func makeNode(context: Context) throws -> Node {
        return try Node(node: [
            "plan_id" : plan_id,
            "vendor_id" : vendor_id
        ]).add(objects: [
            "id" : id,
            "box_id" : box_id
        ])
    }
    
    static func prepare(_ database: Database) throws {
        try database.create(self.entity) { vendorCustomer in
            vendorCustomer.id()
            vendorCustomer.parent(Box.self)
            vendorCustomer.string("plan_id")
            vendorCustomer.parent(Vendor.self)
        }
    }
    
    static func revert(_ database: Database) throws {
        try database.delete(self.entity)
    }
}
