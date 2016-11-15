//
//  BoxResource.swift
//  subber-api
//
//  Created by Hakon Hanesand on 11/12/16.
//
//

import Foundation
import Vapor
import HTTP
import Fluent

extension Entity {

    public static func query(forIds ids: [Node]) throws -> Query<Self> {
        guard let idKey = database?.driver.idKey else {
            throw EntityError.noDatabase
        }

        return try Self.query().filter(idKey, .`in`, ids)
    }
}

enum Curated: String, StringInitializable, NodeInitializable {
    case featured = "featured"
    case staffpicks = "staffpicks"
    case new = "new"

    init(node: Node, in context: Context = EmptyNode) throws {
        guard let string = node.string else {
            throw NodeError.unableToConvert(node: node, expected: "\(String.self)")
        }

        guard let curated = try Curated(from: string) else {
            throw Abort.custom(status: .badRequest, message: "")
        }

        self = curated
    }

    init?(from string: String?) throws {
        guard let _string = string else {
            return nil
        }

        try self.init(from: _string)
    }

    init?(from string: String) throws {
        guard let instance = Curated.init(rawValue: string) else {
            return nil
        }

        self = instance
    }


    func query() throws -> Query<Box> {
        switch self {
        case .staffpicks: fallthrough
        case .featured:
            return try Box.query().union(FeaturedBox.self, localKey: "id", foreignKey: "box_id").filter("type", self.rawValue)

        case .new:
            let query = try Box.query().sort("publish_date", .descending)
            query.limit = Limit(count: 4)
            return query
        }
    }
}

final class BoxController: ResourceRepresentable {

    func index(_ request: Request) throws -> ResponseRepresentable {

        var query = try Box.query()

        if let curated = try Curated(from: request.query?["curated"]?.string) {
            query = try curated.query()
        }

        print(query.sql)
        return try query.all().makeJSON()
    }

    func create(_ request: Request) throws -> ResponseRepresentable {
        var box = try Box(json: request.json())
        try box.save()
        return try Response(status: .created, json: box.makeJSON())
    }

    func delete(_ request: Request, box: Box) throws -> ResponseRepresentable {
        try box.delete()
        return Response(status: .noContent)
    }

    func makeResource() -> Resource<Box> {
        return Resource(
            index: index,
            store: create,
            destroy: delete
        )
    }
}
