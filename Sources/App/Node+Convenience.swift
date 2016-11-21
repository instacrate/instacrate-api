//
//  Node+Convenience.swift
//  subber-api
//
//  Created by Hakon Hanesand on 11/18/16.
//
//

import Foundation
import Node
import JSON
import Fluent

extension Node: JSONConvertible {

    mutating func substitute(key: String, model: Model) throws -> Node {
        precondition(!key.hasSuffix("_id"))
        
        self["\(key)_id"] = nil
        self[key] = try model.makeNode()
        
        return self
    }
}
