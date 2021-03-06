//
//  Shipping.swift
//  subber-api
//
//  Created by Hakon Hanesand on 9/27/16.
//
//

import Vapor
import Fluent
import Sanitized

final class Shipping: Model, Preparation, JSONConvertible, Sanitizable {
    
    static var permitted: [String] = ["customer_id", "address", "firstName", "lastName", "apartment", "city", "state", "zip", "isDefault", "number"]
    
    var id: Node?
    var exists = false
    
    let firstName: String
    let lastName: String
    
    let address: String
    let apartment: String?
    
    let city: String
    let state: String
    let zip: String
    let number: String?
    var isDefault: Bool
    
    var customer_id: Node?
    
    init(node: Node, in context: Context) throws {
        id = try? node.extract("id")
        
        customer_id = try node.extract("customer_id")
        address = try node.extract("address")
        firstName = try node.extract("firstName")
        lastName = try node.extract("lastName")
        city = try node.extract("city")
        state = try node.extract("state")
        zip = try node.extract("zip")
        number = try node.extract("number")
        isDefault = try node.extract("isDefault") ?? false
        apartment = try node.extract("apartment")
    }
    
    func makeNode(context: Context) throws -> Node {
        return try Node(node: [
            "address" : .string(address),
            "city" : .string(city),
            "state" : .string(state),
            "zip" : .string(zip),
            "customer_id" : customer_id!,
            "isDefault" : .bool(isDefault),
            "firstName" : .string(firstName),
            "lastName" : .string(lastName),
        ]).add(objects: [
            "id" : id,
             "apartment" : apartment,
            "number" : number
        ])
    }
    
    func postValidate() throws {
        guard (try? user().first()) ?? nil != nil else {
            throw ModelError.missingLink(from: Shipping.self, to: Customer.self, id: customer_id?.int)
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
            shipping.string("firstName")
            shipping.string("lastName")
            shipping.string("number")
            shipping.bool("isDefault")
            shipping.parent(Customer.self, optional: false)
        })
    }
    
    static func revert(_ database: Database) throws {
        try database.delete(self.entity)
    }
}

extension Shipping {
    
    func orders() -> Children<Order> {
        return fix_children()
    }
    
    func user() throws -> Parent<Customer> {
        return try parent(customer_id)
    }
}

extension Shipping: Relationable {
    
    typealias Relations = (orders: [Order], user: Customer)
    
    func relations() throws -> (orders: [Order], user: Customer) {
        let orders = try self.orders().all()
        
        guard let user = try self.user().get() else {
            throw Abort.custom(status: .internalServerError, message: "Missing user relation for shipping address")
        }
        
        return (orders, user)
    }
}
