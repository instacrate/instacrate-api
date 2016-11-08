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
    
    static var requiredJSONFields = ["user_id", "address", "apartment", "city", "state", "zip"]
    
    var id: Node?
    var exists = false
    
    let address: String
    let apartment: String
    
    let city: String
    let state: String
    let zip: String
    
    var user_id: Node?
    
    init(node: Node, in context: Context) throws {
        id = try? node.extract("id")
        user_id = try node.extract("user_id")
        
        address = try node.extract("address")
        apartment = (try? node.extract("apartment")) ?? ""
        
        city = try node.extract("city")
        state = try node.extract("state")
        zip = try node.extract("zip")
    }
    
    func makeNode(context: Context) throws -> Node {
        return try Node(node: [
            "address" : .string(address),
            "user_id" : user_id!
        ]).add(objects: ["id" : id,
                         "user_id" : user_id])
    }
    
    static func prepare(_ database: Database) throws {
        try database.create(self.entity, closure: { shipping in
            shipping.id()
            shipping.string("address")
            shipping.string("apartment")
            shipping.string("city")
            shipping.string("state")
            shipping.string("zip")
            shipping.parent(User.self, optional: false)
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
    
    func user() throws -> Parent<User> {
        return try parent(user_id)
    }
}

extension Shipping: Relationable {
    
    typealias Relations = (orders: [Order], user: User)
    
    func relations() throws -> (orders: [Order], user: User) {
        let orders = try self.orders().all()
        
        guard let user = try self.user().get() else {
            throw Abort.custom(status: .internalServerError, message: "Missing user relation for shipping address")
        }
        
        return (orders, user)
    }
}
