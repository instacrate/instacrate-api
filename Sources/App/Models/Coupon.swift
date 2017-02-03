//
//  Coupon.swift
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

final class Coupon: Model, JSONConvertible, Preparation, Sanitizable {

    static var permitted: [String] = [""]

    var id: Node?
    var exists = false

    var code: String
    var discount: String
    
    var customerEmail: String

    init(node: Node, in context: Context = EmptyNode) throws {
        id = node["id"]
        code = try node.extract("code")
        discount = try node.extract("discount")
        customerEmail = try node.extract("customerEmail")
    }

    func makeNode(context: Context = EmptyNode) throws -> Node {
        return try Node(node: [
            "code" : .string(code),
            "customerEmail": .string(customerEmail)
        ]).add(objects: [
            "id" : id
        ])
    }
    
    static func prepare(_ database: Database) throws {
        try database.create(self.entity) { coupon in
            coupon.string("code")
            coupon.string("customerEmail")
            coupon.id()
        }
    }
    
    static func revert(_ database: Database) throws {
        try database.delete(self.entity)
    }
}
