//
//  Picture.swift
//  subber-api
//
//  Created by Hakon Hanesand on 9/27/16.
//
//

import Vapor
import Fluent

final class Picture: Model, Preparation, NodeInitializable, NodeRepresentable, Entity {
    
    var id: Node?
    var exists = false
    
    let url: String
    
    var boxId: Node?
    
    init(node: Node, in context: Context) throws {
        id = try node.extract("id")
        url = try node.extract("url")
        boxId = try node.extract("boxId")
    }
    
    init(id: String? = nil, url: String, boxId: String) {
        self.id = id.flatMap { .string($0) }
        self.url = url
        self.boxId = .string(boxId)
    }
    
    func makeNode(context: Context) throws -> Node {
        return try Node(node: [
            "id" : id!,
            "url" : .string(url),
            "boxId" : boxId!
        ])
    }
    
    static func prepare(_ database: Database) throws {
        try database.create(self.entity, closure: { vendor in
            vendor.id()
            vendor.string("url")
            vendor.parent(Box.self, optional: false)
        })
    }
    
    static func revert(_ database: Database) throws {
        try database.delete(self.entity)
    }
}

extension Picture {
    
    func box() throws -> Parent<Box> {
        return try parent(boxId)
    }
}
