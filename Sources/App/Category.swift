//
//  Category.swift
//  subber-api
//
//  Created by Hakon Hanesand on 9/27/16.
//
//

import Vapor
import Fluent

final class Category: Model, Preparation, JSONConvertible {
    
    var id: Node?
    var exists = false
    
    public static var entity = "categories"
    
    let name: String
    
    init(node: Node, in context: Context) throws {
        id = try node.extract("id")
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
    
    typealias boxNode = AnyRelationNode<Vendor, Box, Many>
    
    func queryForRelation<R: Relation>(relation: R.Type) throws -> Query<R.Target> {
        switch R.self {
        case is boxNode.Rel.Type:
            return try siblings().makeQuery()
        default:
            throw Abort.custom(status: .internalServerError, message: "No such relation for category")
        }
    }
    
    func relations(forFormat format: Format) throws -> [Box] {
        return try boxNode.run(onModel: self, forFormat: format)
    }
}
