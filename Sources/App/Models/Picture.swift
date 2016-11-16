//
//  Picture.swift
//  subber-api
//
//  Created by Hakon Hanesand on 9/27/16.
//
//

import Vapor
import Fluent

final class Picture: Model, Preparation, JSONConvertible {
    
    var id: Node?
    var exists = false
    
    let url: String
    
    var box_id: Node?
    
    init(node: Node, in context: Context) throws {
        id = try node.extract("id")
        url = try node.extract("url")
        box_id = try node.extract("box_id")
    }
    
    init(id: String? = nil, url: String, box_id: String) {
        self.id = id.flatMap { .string($0) }
        self.url = url
        self.box_id = .string(box_id)
    }
    
    func makeNode(context: Context) throws -> Node {
        return try Node(node: [
            "url" : .string(url),
            "box_id" : box_id!
        ]).add(name: "id", node: id)
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
        return try parent(box_id)
    }
}

extension Picture: Relationable {
    
    typealias Relations = Box

    func relations() throws -> Box {
        guard let box = try box().get() else {
            throw Abort.custom(status: .internalServerError, message: "Missing box relation for picture with id \(id) and url \(url).")
        }
        
        return box
    }
}

