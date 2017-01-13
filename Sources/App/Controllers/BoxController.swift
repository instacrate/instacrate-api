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

final class BoxController: ResourceRepresentable {

    func index(_ request: Request) throws -> ResponseRepresentable {
        let curated = try request.extract() as Box.Curated
        let sorted = try request.extract() as Box.Sort
        
        let query = try curated.makeQuery().apply(sorted)
        
        let format = try request.extract() as Box.Format

        return try format.apply(on: query.all()).makeJSON()
    }
    
    func show(_ request: Request, box: Box) throws -> ResponseRepresentable {
        let format = try request.extract() as Box.Format
        return try format.apply(on: box).makeJSON()
    }

    func create(_ request: Request) throws -> ResponseRepresentable {
        
        var node = try request.json().node
        let bullets = try node.extract("bullets") as [String]
        node["bullets"] = Node.string(bullets.joined(separator: Box.boxBulletSeparator))
        
        try print(node.extract("bullets") as String)
        
        var box = try Box(node: node)

        guard try box.vendor().get() != nil else {
            throw Abort.custom(status: .badRequest, message: "There is no vendor with id \(box.vendor_id?.int)")
        }

        try box.save()
        return try Response(status: .created, json: box.makeJSON())
    }

    func delete(_ request: Request, box: Box) throws -> ResponseRepresentable {
        try box.delete()
        return Response(status: .noContent)
    }

    func modify(_ request: Request, _box: Box) throws -> ResponseRepresentable {
        guard try _box.vendor_id == request.vendor().id else {
            throw Abort.custom(status: .forbidden, message: "Can not modify another user's shipping address.")
        }

        var box = _box
        let json = try request.json()

        var updated = try box.update(from: json)
        try updated.save()
        
        return try updated.makeResponse()
    }

    func makeResource() -> Resource<Box> {
        return Resource(
            index: index,
            store: create,
            show: show,
            modify: modify,
            destroy: delete
        )
    }
}
