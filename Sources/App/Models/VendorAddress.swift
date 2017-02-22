//
//  VendorAddress.swift
//  instacrate-api
//
//  Created by Hakon Hanesand on 2/21/17.
//
//

import Vapor
import Fluent
import Sanitized

final class VendorAddress: Model, Preparation, JSONConvertible, Sanitizable {
    
    static var permitted: [String] = ["vendor_id", "address", "apartment", "city", "state", "zip"]
    
    var id: Node?
    var exists = false
    
    let address: String
    let apartment: String?
    
    let city: String
    let state: String
    let zip: String
    
    var vendor_id: Node?
    
    init(node: Node, in context: Context) throws {
        id = try? node.extract("id")
        
        vendor_id = try node.extract("vendor_id")
        address = try node.extract("address")
        city = try node.extract("city")
        state = try node.extract("state")
        zip = try node.extract("zip")
        
        apartment = try? node.extract("apartment")
    }
    
    func makeNode(context: Context) throws -> Node {
        return try Node(node: [
            "address" : .string(address),
            "city" : .string(city),
            "state" : .string(state),
            "zip" : .string(zip)
        ]).add(objects: [
            "id" : id,
             "apartment" : apartment,
             "vendor_id" : vendor_id
        ])
    }
    
    func postValidate() throws {
        guard (try? vendor().first()) ?? nil != nil else {
            throw ModelError.missingLink(from: Shipping.self, to: Customer.self, id: vendor_id?.int)
        }
    }
    
    static func prepare(_ database: Database) throws {
        try database.create(self.entity, closure: { shipping in
            shipping.id()
            shipping.string("address")
            shipping.string("apartment", optional: true)
            shipping.string("city")
            shipping.string("state")
            shipping.string("zip")
            shipping.parent(Vendor.self, optional: false)
        })
    }
    
    static func revert(_ database: Database) throws {
        try database.delete(self.entity)
    }
}

extension VendorAddress {
    
    func vendor() throws -> Parent<Vendor> {
        return try parent(vendor_id)
    }
}
