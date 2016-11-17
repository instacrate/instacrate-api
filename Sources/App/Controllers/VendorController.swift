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
        return try request.vendor()
    }
    
    func create(_ request: Request) throws -> ResponseRepresentable {
        var vendor = try Vendor(json: request.json())
        try vendor.save()
        return try Response(status: .created, json: vendor.makeJSON())
    }
    
    func modify(_ request: Request, _vendor: Vendor) throws -> ResponseRepresentable {
        var vendor = _vendor
        
        try vendor.update(withJSON: request.json())
        try vendor.save()
        return try Response(status: .created, json: vendor.makeJSON())
    }
    
    func makeResource() -> Resource<Vendor> {
        return Resource(
            store: create,
            modify: modify
        )
    }
}
