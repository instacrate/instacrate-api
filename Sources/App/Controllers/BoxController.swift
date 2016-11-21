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
        
        return try curated.makeQuery().apply(sorted).all().makeJSON()
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
