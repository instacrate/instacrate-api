//
//  BaseViewCollection.swift
//  subber-api
//
//  Created by Hakon Hanesand on 11/18/16.
//
//

import Foundation
import Vapor
import HTTP
import Routing
import JSON
import Node
import Fluent

extension Node {
    
    mutating func substitute(key: String, model: Model) throws -> Node {
        precondition(!key.hasSuffix("_id"))
        
        self["\(key)_id"] = nil
        self[key] = try model.makeNode()
        
        return self
    }
}
