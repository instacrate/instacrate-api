//
//  Review.swift
//  subber-api
//
//  Created by Hakon Hanesand on 9/27/16.
//
//

import Vapor
import Fluent

final class Review: Model, Preparation, JSONConvertible {
    
    var id: Node?
    var exists = false
    
    let description: String
    let rating: Int
    let date: String
    
    var box_id: Node?
    var user_id: Node?
    
    init(node: Node, in context: Context) throws {
        id = try node.extract("id")
        description = try node.extract("description")
        rating = try node.extract("rating")
        date = try node.extract("date")
        box_id = try node.extract("box_id")
        user_id = try node.extract("user_id")
    }
    
    init(id: String? = nil, description: String, rating: Int, date: String, box_id: String, user_id: String) {
        self.id = id.flatMap { .string($0) }
        self.description = description
        self.rating = rating
        self.date = date
        self.box_id = .string(box_id)
        self.user_id = .string(user_id)
    }
    
    func makeNode(context: Context) throws -> Node {
        return try Node(node: [
            "description" : .string(description),
            "rating" : .number(.int(rating)),
            "date" : .string(date),
            "box_id" : box_id!,
            "user_id" : user_id!
        ]).add(name: "id", node: id)
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
        return try parent(box_id)
    }
    
    func user() throws -> Parent<User> {
        return try parent(user_id)
    }
}

extension Review: Relationable {
    
    typealias Relations = (user: User, box: Box)

    func relations() throws -> (user: User, box: Box) {
        guard let user = try self.user().get() else {
            throw Abort.custom(status: .internalServerError, message: "Missing user relation for review with description \(description)")
        }
        
        guard let box = try self.box().get() else {
            throw Abort.custom(status: .internalServerError, message: "Missing box relation for review with description \(description)")
        }
        
        return (user, box)
    }
}
