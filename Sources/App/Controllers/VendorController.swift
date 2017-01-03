//
//  VendorController.swift
//  subber-api
//
//  Created by Hakon Hanesand on 11/15/16.
//
//

import Foundation
import Vapor
import HTTP

final class VendorController: ResourceRepresentable {

    func index(_ request: Request) throws -> ResponseRepresentable {
        return try request.vendor().makeJSON()
    }
    
    func show(_ request: Request, vendor: Vendor) throws -> ResponseRepresentable {
        return try vendor.makeJSON()
    }
    
    func create(_ request: Request) throws -> ResponseRepresentable {
        var vendor = try Vendor(json: request.json())
        try vendor.save()
        return try Response(status: .created, json: vendor.makeJSON())
    }

    func modify(_ request: Request, _vendor: Vendor) throws -> ResponseRepresentable {
        guard try request.vendor().id == _vendor.id else {
            throw Abort.custom(status: .forbidden, message: "Can not modify another another vendor.")
        }

        var vendor = _vendor
        let json = try request.json()

        var updated = try vendor.update(from: json)
        try updated.save()

        return try updated.makeResponse()
    }
    
    func makeResource() -> Resource<Vendor> {
        return Resource(
            index: index,
            store: create,
            show: show,
            modify: modify
        )
    }
}
