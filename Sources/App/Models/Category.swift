//
//  Category.swift
//  subber-api
//
//  Created by Hakon Hanesand on 9/27/16.
//
//

import Vapor
import Fluent
import Sanitized

final class Category: Model, Preparation, JSONConvertible, Sanitizable {
    
    static var permitted = ["name"]
    
    var id: Node?
    var exists = false
    
    public static var entity = "categories"
    
    let name: String
    
    init(node: Node, in context: Context) throws {
        id = try? node.extract("id")
        name = try node.extract("name")
    }
    
    init(id: String? = nil, name: String) {
        self.id = id.flatMap { .string($0) }
        self.name = name
    }
    
    func makeNode(context: Context) throws -> Node {
        return try Node(node: [
            "name" : .string(name)
        ]).add(name: "id", node: id)
    }
    
    static func prepare(_ database: Database) throws {
        try database.create(self.entity, closure: { vendor in
            vendor.id()
            vendor.string("name")
        })
    }
    
    static func revert(_ database: Database) throws {
        try database.delete(self.entity)
    }
}

extension Category {
    
    func boxes() throws -> Siblings<Box> {
        return try siblings()
    }
}

extension Category: Relationable {

    typealias Relations = [Box]

    func relations() throws -> [Box] {
        return try boxes().all()
    }
}
