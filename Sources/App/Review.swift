//
//  Review.swift
//  subber-api
//
//  Created by Hakon Hanesand on 9/27/16.
//
//

import Vapor
import Fluent

final class Review: Model, Preparation, NodeInitializable, NodeRepresentable, Entity {
    
    var id: Node?
    var exists = false
    
    let description: String
    let rating: String
    let date: String
    
    var boxId: Node?
    var userId: Node?
    
    init(node: Node, in context: Context) throws {
        id = try node.extract("id")
        description = try node.extract("name")
        rating = try node.extract("rating")
        date = try node.extract("date")
        boxId = try node.extract("bodId")
        userId = try node.extract("userId")
    }
    
    init(id: String? = nil, description: String, rating: String, date: String, boxId: String, userId: String) {
        self.id = id.flatMap { .string($0) }
        self.description = description
        self.rating = rating
        self.date = date
        self.boxId = .string(boxId)
        self.userId = .string(userId)
    }
    
    func makeNode(context: Context) throws -> Node {
        return try Node(node: [
            "id" : id!,
            "description" : .string(description),
            "rating" : .string(rating),
            "date" : .string(date),
            "boxId" : boxId!,
            "userId" : userId!
        ])
    }
    
    static func prepare(_ database: Database) throws {
        try database.create(self.entity, closure: { box in
            box.id()
            box.string("description")
            box.string("rating")
            box.string("date")
            box.parent(Box.self, optional: false)
            box.parent(User.self, optional: false)
        })
    }
    
    static func revert(_ database: Database) throws {
        try database.delete(self.entity)
    }
}

extension Review {
    
    func box() throws -> Parent<Box> {
        return try parent(boxId)
    }
    
    func user() throws -> Parent<User> {
        return try parent(userId)
    }
}
