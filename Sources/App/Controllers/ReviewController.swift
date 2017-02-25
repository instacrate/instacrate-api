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

extension Review {
    
    func shouldAllow(request: Request) throws {
        do {
            try request.has(session: .customer)
        } catch {
            throw try Abort.custom(status: .forbidden, message: "Method \(request.method) is not allowed on resource Review(\(throwableId())) by this user. Must be logged in as Customer(\(customer_id?.int ?? 0)).")
        }
        
        let customer = try request.customer()
        
        guard try customer.throwableId() == customer_id?.int else {
            throw try Abort.custom(status: .forbidden, message: "This Customer(\(customer.throwableId())) does not have access to resource Review(\(throwableId()). Must be logged in as Customer(\(customer_id?.int ?? 0).")
        }
    }
}

final class ReviewController: ResourceRepresentable {
    
    func create(_ request: Request) throws -> ResponseRepresentable {
        var review: Review = try request.extractModel(injecting: request.customerInjectable())
        try review.save()
        return review
    }
    
    func modify(_ request: Request, review: Review) throws -> ResponseRepresentable {
        try review.shouldAllow(request: request)
        
        var review: Review = try request.patchModel(review)
        try review.save()
        return try Response(status: .ok, json: review.makeJSON())
    }
    
    func makeResource() -> Resource<Review> {
        return Resource(
            store: create,
            modify: modify
        )
    }
}
