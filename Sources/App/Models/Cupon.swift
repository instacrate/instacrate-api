//
//  Cupon.swift
//  subber-api
//
//  Created by Hakon Hanesand on 2/1/17.
//
//

import Foundation
import Vapor
import Auth
import Fluent
import Sanitized

final class Cupon: Model, JSONConvertible, Preparation, Sanitizable {

    static var permitted: [String] = [""]

    var id: Node?
    var exists = false

    var code: String
    var discount: String
    
    var customer_id: Node?

    init(node: Node, in context: Context = EmptyNode) throws {
        id = node["id"]
        code = try node.extract("code")
        discount = try node.extract("discount")
        customer_id = try node.extract("customer_id")
    }

    func makeNode(context: Context = EmptyNode) throws -> Node {
        return try Node(node: [
            "code" : .string(code)
        ]).add(objects: [
            "id" : id,
            "customer_id": customer_id
        ])
    }
    
    static func prepare(_ database: Database) throws {
        try database.create(self.entity) { cupon in
            cupon.string("code")
            cupon.parent(Customer.self)
            cupon.id()
        }
    }
    
    static func revert(_ database: Database) throws {
        try database.delete(self.entity)
    }
}
