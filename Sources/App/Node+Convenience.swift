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
import Vapor

extension Node: JSONConvertible {

    mutating func substitute(key: String, model: Model) throws -> Node {
        precondition(!key.hasSuffix("_id"))
        
        self["\(key)_id"] = nil
        self[key] = try model.makeNode()
        
        return self
    }

    mutating func merge(with json: JSON) throws -> Node {
        guard let update = json.node.nodeObject else {
            throw Abort.custom(status: .badRequest, message: "Expected [String : Object] node but got \(json.node)")
        }

        for (key, object) in update {
            self[key] = object
        }

        return self
    }
}

extension Model {

    mutating func update(from json: JSON) throws -> Self {
        var node = try self.makeNode()
        var result = try Self.init(node: node.merge(with: json), in: EmptyNode)
        result.exists = self.exists
        return result
    }
}

internal extension Node {
    
    func add(name: String, node: Node?) throws -> Node {
        if let node = node {
            return try add(name: name, node: node)
        }
        
        return self
    }
    
    func add(name: String, node: Node) throws -> Node {
        guard var object = self.nodeObject else { throw NodeError.unableToConvert(node: self, expected: "[String: Node].self") }
        object[name] = node
        return try Node(node: object)
    }
    
    func add(objects: [String : NodeConvertible?]) throws -> Node {
        guard var nodeObject = self.nodeObject else { throw NodeError.unableToConvert(node: self, expected: "[String: Node].self") }
        
        for (name, object) in objects {
            if let node = try object?.makeNode() {
                nodeObject[name] = node
            }
        }
        
        return try Node(node: nodeObject)
    }
}
