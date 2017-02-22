//
//  BoxResource.swift
//  subber-api
//
//  Created by Hakon Hanesand on 11/12/16.
//
//

import Foundation
import Vapor
import enum HTTP.Method
import HTTP
import Fluent

extension Box {
    
    func shouldAllow(request: Request) throws {
        switch request.sessionType {
        case .vendor:
            let vendor = try request.vendor()
            
            guard try vendor.throwableId() == vendor_id?.int else {
                throw try Abort.custom(status: .forbidden, message: "This Vendor(\(vendor.throwableId()) does not have access to resource Box(\(throwableId()). Must be logged in as Vendor(\(vendor_id?.int ?? 0).")
            }
            
        case .customer: fallthrough
        case .none:
            throw try Abort.custom(status: .forbidden, message: "Method \(request.method) is not allowed on resource Box(\(throwableId())) by this user. Must be logged in as Vendor(\(vendor_id?.int ?? 0)).")
        }
    }
}

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
        try? request.has(session: .vendor)
        
        if let bullets: [String] = try request.json().node.extract("bullets") {
            request.json?["bullets"] = JSON(Node.string(bullets.joined(separator: Box.boxBulletSeparator)))
        }
        
        var box: Box = try request.extractModel(injecting: request.vendorInjectable())
        try box.save()
        return box
    }

    func delete(_ request: Request, box: Box) throws -> ResponseRepresentable {
        try box.shouldAllow(request: request)
        
        try box.delete()
        return Response(status: .noContent)
    }

    func modify(_ request: Request, box: Box) throws -> ResponseRepresentable {
        try box.shouldAllow(request: request)
        
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
