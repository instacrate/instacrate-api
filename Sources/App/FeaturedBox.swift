//
//  FeaturedBox.swift
//  subber-api
//
//  Created by Hakon Hanesand on 10/12/16.
//
//

import Vapor
import Fluent
import Foundation

final class FeaturedBox: Model, Preparation, JSONConvertible {
    
    var id: Node?
    var exists = false
    
    public static var entity = "featured_boxes"
    
    var box_id: Node?
    
    init(node: Node, in context: Context) throws {
        id = try node.extract("id")
        box_id = try node.extract("box_id")
    }
    
    init(id: String? = nil, boxId: String) {
        self.id = id.flatMap { .string($0) }
        self.box_id = .string(boxId)
    }
    
    func makeNode(context: Context) throws -> Node {
        return try Node(node: [
            "box_id" : box_id!
        ]).add(name: "id", node: id)
    }
    
    static func prepare(_ database: Database) throws {
        try database.create(self.entity, closure: { box in
            box.id()
            box.parent(Box.self, optional: false)
        })
    }
    
    static func revert(_ database: Database) throws {
        try database.delete(self.entity)
    }
}

extension FeaturedBox {
    
    func box() throws -> Parent<Box> {
        return try parent(box_id)
    }
}
