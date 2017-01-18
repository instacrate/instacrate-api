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
        var modify: Review = try request.extractModel()
        try modify.save()
        return modify
        
//        var review = try Review(json: request.json())
//        let customer = try request.customer()
//
//        if review.customer_id != nil {
//            guard review.customer_id == customer.id else {
//                throw Abort.custom(status: .badRequest, message: "User id provided in object does not match logged in user.")
//            }
//        } else {
//            review.customer_id = customer.id
//        }
//
//        guard try review.box().get() != nil else {
//            throw Abort.custom(status: .badRequest, message: "No such box with id \(review.box_id)")
//        }
//
//        try review.save()
//        return try Response(status: .created, json: review.makeJSON())
    }
    
    func modify(_ request: Request, review: Review) throws -> ResponseRepresentable {
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
