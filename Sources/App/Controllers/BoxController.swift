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

extension RawRepresentable where RawValue == String {
    
    public init?(from string: String) throws {
        self.init(rawValue: string)
    }
    
    public init?(from _string: String?) throws {
        guard let string = _string else {
            return nil
        }
        
        self.init(rawValue: string)
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

        guard let curated = Curated(rawValue: string) else {
            throw Abort.custom(status: .badRequest, message: "Invalid value for curated in request query string.")
        }

        self = curated
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

enum BoxSorting: String, NodeConvertible {
    
    case alphabetical = "alphabetical"
    case price = "price"
    case new = "new"
    
    private static let all: [BoxSorting] = [.alphabetical, .price, .new]
    
    init(node: Node, in context: Context = EmptyNode) throws {
        guard let string = node.string else {
            throw NodeError.unableToConvert(node: node, expected: "\(String.self)")
        }
        
        guard let sorting = BoxSorting(rawValue: string) else {
            throw Abort.custom(status: .badRequest, message: "Invalid value for box sorting. Valid values are \(BoxSorting.all.map { $0.rawValue })")
        }
        
        self = sorting
    }
    
    func makeNode(context: Context = EmptyNode) -> Node {
        return .string(rawValue)
    }
    
    var field: String {
        switch self {
        case .alphabetical:
            return "name"
        case .price:
            return "price"
        case .new:
            return "publish_date"
        }
    }
    
    var direction: Sort.Direction {
        return .ascending
    }
}

extension QueryRepresentable {
    
    @discardableResult
    func sort(_ sorting: BoxSorting) throws -> Query<T> {
        return try self.sort(sorting.field, sorting.direction)
    }
}

final class BoxController: ResourceRepresentable {

    func index(_ request: Request) throws -> ResponseRepresentable {

        var query = try Box.query()

        if let curated = try Curated(from: request.query?["curated"]?.string) {
            query = try curated.query()
        }
        
        if let sorting = try BoxSorting(from: request.query?["sort"]?.string) {
            try query.sort(sorting)
        }

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
