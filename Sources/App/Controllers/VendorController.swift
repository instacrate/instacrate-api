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
        var vendor: Vendor = try request.extractModel()
        try vendor.save()
        return vendor
    }

    func modify(_ request: Request, vendor: Vendor) throws -> ResponseRepresentable {
        var vendor: Vendor = try request.patchModel(vendor)
        try vendor.save()
        return try Response(status: .ok, json: vendor.makeJSON())
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
