//
//  ReviewController.swift
//  subber-api
//
//  Created by Hakon Hanesand on 11/15/16.
//
//

import Foundation
import Vapor
import HTTP

final class ReviewController: ResourceRepresentable {
    
    func create(_ request: Request) throws -> ResponseRepresentable {
        var review = try Review(json: request.json())
        try review.save()
        return try Response(status: .created, json: review.makeJSON())
    }
    
    func index(_ request: Request, category: Category) -> ResponseRepresentable {
        return ""
    }
    
    func makeResource() -> Resource<Review> {
        return Resource(
            store: create
        )
    }
}
