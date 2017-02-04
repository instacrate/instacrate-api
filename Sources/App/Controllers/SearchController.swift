//
//  SearchController.swift
//  subber-api
//
//  Created by Hakon Hanesand on 11/15/16.
//
//

import Foundation
import Vapor
import HTTP

final class SearchController: ResourceRepresentable {
    
    func index(_ request: Request) throws -> ResponseRepresentable {
        let boxes = try Box.query().all()
        return JSON(.array(boxes.map { .string($0.name) }))
    }
    
    func makeResource() -> Resource<Box> {
        return Resource(
            index: index
        )
    }
}
