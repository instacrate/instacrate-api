//
//  VendorCustomer.swift
//  subber-api
//
//  Created by Hakon Hanesand on 1/22/17.
//
//

import Foundation
import Vapor
import Fluent

final class VendorCustomer: Model, Preparation {
    
    var id: Node?
    var exists: Bool = false
    
    let customer_id: Node?
    let vendor_id: Node?
    let connectAccountCustomerId: String
    
    init(vendor: Vendor, customer: Customer, account: String) throws {
        guard let vendor_id = vendor.id else {
            throw Abort.custom(status: .internalServerError, message: "Missing vendor id for VendorCustomer link.")
        }
        
        guard let customer_id = customer.id else {
            throw Abort.custom(status: .internalServerError, message: "Missing customer id for VendorCustomer link.")
        }
    
        self.customer_id = customer_id
        self.vendor_id = vendor_id
        self.connectAccountCustomerId = account
    }
    
    init(node: Node, in context: Context) throws {
        id = node["id"]
        customer_id = try node.extract("customer_id")
        vendor_id = try node.extract("vendor_id")
        connectAccountCustomerId = try node.extract("connectAccountCustomerId")
    }
    
    func makeNode(context: Context) throws -> Node {
        return try Node(node: [
            "customer_id" : customer_id,
            "vendor_id" : vendor_id
        ]).add(objects: [
            "id" : id,
            "connectAccountCustomerId" : connectAccountCustomerId
        ])
    }
    
    static func prepare(_ database: Database) throws {
        try database.create(self.entity) { vendorCustomer in
            vendorCustomer.id()
            vendorCustomer.parent(Customer.self)
            vendorCustomer.parent(Vendor.self)
            vendorCustomer.string("connectAccountCustomerId")
        }
    }
    
    static func revert(_ database: Database) throws {
        try database.delete(self.entity)
    }
}

extension VendorCustomer {
    
    func vendor() throws -> Parent<Vendor> {
        return try parent(vendor_id)
    }
    
    func customer() throws -> Parent<Customer> {
        return try parent(customer_id)
    }
}
