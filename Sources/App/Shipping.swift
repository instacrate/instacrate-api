//
//  Shipping.swift
//  subber-api
//
//  Created by Hakon Hanesand on 9/27/16.
//
//

import Vapor
import Fluent

final class Shipping: Model, Preparation, JSONConvertible {
    
    var id: Node?
    var exists = false
    
    let address: String
    let appartment: String
    
    let city: String
    let state: String
    let zip: String
    
    var user_id: Node?
    
    init(node: Node, in context: Context) throws {
        id = try? node.extract("id")
        user_id = try? node.extract("user_id")
        
        address = try node.extract("address")
        appartment = try node.extract("appartment")
        
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
            shipping.id("user_id")
            shipping.string("address")
            shipping.string("appartment")
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
    
    typealias orderNode = AnyRelationNode<Shipping, Order, Many>
    typealias userNode = AnyRelationNode<Shipping, User, One>
    
    func queryForRelation<R: Relation>(relation: R.Type) throws -> Query<R.Target> {
        switch R.self {
        case is orderNode.Rel.Type:
            return try children().makeQuery()
        case is userNode.Rel.Type:
            return try parent(user_id).makeQuery()
        default:
            throw Abort.custom(status: .internalServerError, message: "No such relation for box")
        }
    }
    
    func relations(forFormat format: Format) throws -> ([Order], User) {
        let orders = try orderNode.run(onModel: self, forFormat: format)
        let user = try userNode.run(onModel: self, forFormat: format)
        
        return (orders, user)
    }

}
