//
//  TerseBoxView.swift
//  subber-api
//
//  Created by Hakon Hanesand on 11/18/16.
//
//

import Foundation
import Vapor
import HTTP
import Routing
import Fluent

final class TerseBoxViewCollection: BaseViewCollection {
    
    func createTerseView(forRequest request: Request, box: Box) throws -> ResponseRepresentable {
        let boxReviews = try box.reviews().all()
        
        let numberOfReviews = boxReviews.count
        let averageReviewScore = boxReviews.map { $0.rating }.average
        
        let vendor = try box.vendor().first()
        
        return try box.makeNode().add(objects: ["numberOfReviews" : numberOfReviews, "averateRating" : averageReviewScore, "vendorName" : vendor.contactName]).makeJSON()
    }

    func build<Builder : RouteBuilder>(_ builder: Builder) where Builder.Value == Wrapped {
        
        builder.get("box", "short", Box.self) { request, box in
            return try self.createTerseView(forRequest: request, box: box)
        }
    }
}
