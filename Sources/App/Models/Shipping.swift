//
//  Shipping.swift
//  subber-api
//
//  Created by Hakon Hanesand on 9/27/16.
//
//

import Vapor
import Fluent

protocol FastInitializable {
    
    static var requiredJSONFields: [String] { get }
}

final class Shipping: Model, Preparation, JSONConvertible, FastInitializable {
    
    static var requiredJSONFields = ["customer_id", "address", "apartment", "city", "state", "zip"]
    
    var id: Node?
    var exists = false
    
    let firstName: String
    let lastName: String
    
    let address: String
    let apartment: String
    
    let city: String
    let state: String
    let zip: String
    var isDefault: Bool
    
    var customer_id: Node?
    
    init(node: Node, in context: Context) throws {
        id = try? node.extract("id")
        customer_id = try node.extract("customer_id")
        isDefault = (try? node.extract("isDefault")) ?? false
        
        address = try node.extract("address")
        apartment = try node.extract("apartment")
        
        firstName = try node.extract("firstName")
        lastName = try node.extract("lastName")
        
        city = try node.extract("city")
        state = try node.extract("state")
        zip = try node.extract("zip")
    }
    
    func makeNode(context: Context) throws -> Node {
        return try Node(node: [
            "address" : .string(address),
            "apartment" : .string(apartment),
            "city" : .string(city),
            "state" : .string(state),
            "zip" : .string(zip),
            "customer_id" : customer_id!,
            "isDefault" : .bool(isDefault),
            "firstName" : .string(firstName),
            "lastName" : .string(lastName)
        ]).add(objects: ["id" : id])
    }
    
    static func prepare(_ database: Database) throws {
        try database.create(self.entity, closure: { shipping in
            shipping.id()
            shipping.string("address")
            shipping.string("apartment")
            shipping.string("city")
            shipping.string("state")
            shipping.string("zip")
            shipping.string("firstName")
            shipping.string("lastName")
            shipping.parent(Customer.self, optional: false)
        })
    }
    
    static func revert(_ database: Database) throws {
        try database.delete(self.entity)
    }
}

extension Shipping {
    
    func orders() -> Children<Order> {
        return children("shipping_id", Order.self)
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
