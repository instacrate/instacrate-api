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
        switch request.sessionType {

        case .vendor:
            let sorted = try request.extract() as Box.Sort
            let format = try request.extract() as Box.Format
            
            let query = try request.vendor().boxes().apply(sorted)
            return try format.apply(on: query.all()).makeJSON()

        case .customer: fallthrough
        case .none:

            let curated = try request.extract() as Box.Curated
            let sorted = try request.extract() as Box.Sort
            let query = try curated.makeQuery().apply(sorted)

            let format = try request.extract() as Box.Format
            return try format.apply(on: query.all()).makeJSON()
        }
    }
    
    func show(_ request: Request, box: Box) throws -> ResponseRepresentable {
        let format = try request.extract() as Box.Format
        return try format.apply(on: box).makeJSON()
    }

    func create(_ request: Request) throws -> ResponseRepresentable {
        if let bullets: [String] = try request.json?.node.extract("bullets") {
            request.json?["bullets"] = JSON(Node.string(bullets.joined(separator: Box.boxBulletSeparator)))
        }
        
        var box: Box = try request.extractModel()
        try box.save()
        return box
    }

    func delete(_ request: Request, box: Box) throws -> ResponseRepresentable {
        try box.delete()
        return Response(status: .noContent)
    }

    func modify(_ request: Request, box: Box) throws -> ResponseRepresentable {
        var box: Box = try request.patchModel(box)
        try box.save()
        return try Response(status: .ok, json: box.makeJSON())
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
