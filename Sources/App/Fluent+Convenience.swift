//
//  Vapor+Convenience.swift
//  subber-api
//
//  Created by Hakon Hanesand on 11/18/16.
//
//

import Foundation
import Fluent
import Vapor

extension Parent {
    
    func first() throws -> T {
        
        guard let result: T = try first() else {
            throw Abort.custom(status: .internalServerError, message: "Relation not found for child \(child) with parent id \(parentId)")
        }
        
        return result
    }
}
