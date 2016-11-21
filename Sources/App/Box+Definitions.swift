//
//  Box+Definitions.swift
//  subber-api
//
//  Created by Hakon Hanesand on 11/18/16.
//
//

import Foundation
import TypeSafeRouting
import Node
import Fluent
import Vapor
import HTTP

extension Box {
    
    enum Curated: String, TypesafeOptionsParameter, QueryRepresentable {
        case featured
        case staffpicks
        case new
        
        static let key = "curated"
        static let values = [Curated.featured.rawValue, Curated.staffpicks.rawValue, Curated.new.rawValue]
        
        func makeQuery() throws -> Query<Box> {
            switch self {
            case .staffpicks: fallthrough
            case .featured:
                return try Box.query().union(FeaturedBox.self, localKey: "id", foreignKey: "box_id").filter(FeaturedBox.self, "type", self.rawValue)
                
            case .new:
                let query = try Box.query().sort("publish_date", .descending)
                query.limit = Limit(count: 4)
                return query
            }
        }
    }
    
    enum Sort: String, TypesafeOptionsParameter {
    
        case alphabetical
        case price
        case new
        
        static let key = "sort"
        static let values = [Sort.alphabetical.rawValue, Sort.price.rawValue, Sort.new.rawValue]
        
        var field: String {
            switch self {
            case .alphabetical:
                return "name"
            case .price:
                return "price"
            case .new:
                return "publish_date"
            }
        }
    }
}
