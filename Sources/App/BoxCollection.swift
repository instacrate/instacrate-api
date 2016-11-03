//
//  ShippingController.swift
//  subber-api
//
//  Created by Hakon Hanesand on 10/1/16.
//
//

import Foundation
import Vapor
import HTTP
import Routing
import JSON
import Node
import Fluent

extension Collection where Iterator.Element == Int, IndexDistance == Int {
    
    var total: Iterator.Element {
        return reduce(0, +)
    }
    
    var average: Double {
        return isEmpty ? 0 : Double(total) / Double(count)
    }
}

fileprivate func createNode(forBox box: Box) throws -> Node {
    let relations = try box.relations()
    
    let reviewNodes = try relations.reviews.map { review -> Node in
        guard let user = try review.user().get() else {
            throw Abort.custom(status: .notFound, message: "User relation missing for review with text \(review.text)")
        }
        
        var node = try review.makeNode()
        
        node["user_id"] = nil
        node["user"] = try user.makeNode()
        
        return node
    }
    
    let nodes = try [
        "vendor" : relations.vendor.makeNode(),
        "reviews" : .array(reviewNodes),
        "pictures" : .array(relations.pictures.map { try $0.makeNode() }),
        "numberOfRatings" : .number(.int(relations.reviews.count)),
        "averageRating" : .number(.double(relations.reviews.map { $0.rating }.average))
    ]
    
    return try box.makeNode().add(objects: nodes)
}

extension Node: JSONRepresentable {
    
    public func makeJSON() throws -> JSON {
        return try JSON(node: self)
    }
}

extension Node: ResponseRepresentable {
    
    public func makeResponse() throws -> Response {
        let json = try makeJSON()
        return try json.makeResponse()
    }
}

enum BoxSorting {
    
    case alphabetical
    case price
    case new
    
    private static let all: [BoxSorting] = [.alphabetical, .price, .new]
    
    static func sortingType(forString string: String) throws -> BoxSorting {
        let names = all.map { ($0, $0.name) }
        let matching = names.filter { $0.1 == string }
        
        guard let type = matching.first?.0 else {
            throw Abort.custom(status: .badRequest, message: "Sorting type \(string) is not allowed. Allowed values are \(all.map { $0.name }.array)")
        }
        
        return type
    }
    
    var name: String {
        switch self {
        case .alphabetical:
            return "alpha"
        case .price:
            return "price"
        case .new:
            return "new"
        }
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
    
    func sort(_ boxSort: BoxSorting?) throws -> Query<T> {
        if let sort = boxSort {
            return try self.sort(sort.field, sort.direction)
        }
        
        return try self.makeQuery()
    }
}

fileprivate extension Request {
    
    func sort() throws -> BoxSorting? {
        guard let sortParameter = self.headers["sort"]?.string else {
            return nil
        }
    
        return try BoxSorting.sortingType(forString: sortParameter)
    }
}

final class BoxCollection : RouteCollection, EmptyInitializable {
    
    init () {}
    
    typealias Wrapped = HTTP.Responder
    
    func build<Builder : RouteBuilder>(_ builder: Builder) where Builder.Value == Responder {
        
        builder.group("box") { box in
            
            box.get(Box.self) { request, box in
                return try createNode(forBox: box)
            }
            
            box.get("category", Category.self) { request, category in
                let boxes = try category.boxes().all()

                return try JSON(node: .array(boxes.map { box in
                    return try createNode(forBox: box)
                }))
            }
            
            box.get("featured") { request in
                let boxes = try FeaturedBox.all().flatMap { try $0.box().get() }
                return try Node.array(boxes.map(createNode(forBox:)))
            }
            
            box.get("new") { request in
                let query = try Box.query().sort("publish_date", .descending)
                query.limit = Limit(count: 10)
                
                let boxes = try query.all()
                
                return try Node.array(boxes.map(createNode(forBox:)))
            }
            
            box.group("all") { all in
                
                all.get() { request in
                    let boxes = try Box.query().sort(request.sort()).all()
                    return try Node.array(boxes.map(createNode(forBox:)))
                }
                
                all.get("names") { request in
                    let boxes = try Box.query().all()
                    let names: [Node] = boxes.map { .string($0.name) }
                    return JSON(.array(names))
                }
            }

            box.get() { request in
                
                guard let ids = request.query?["id"]?.array?.flatMap({ $0.string }) else {
                    throw Abort.custom(status: .badRequest, message: "Expected query parameter with name id.")
                }
                
                let boxes = try Box.query().filter("id", .in, ids).all()
                return try Node.array(boxes.map(createNode(forBox:)))
            }
        }
    }
}
