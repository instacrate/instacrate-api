//
//  Expander.swift
//  instacrate-api
//
//  Created by Hakon Hanesand on 3/12/17.
//
//

import Foundation
import Vapor
import HTTP

extension Request {
    
    func extract<T: QueryInitializable>() throws -> T? {
        return try T.init(node: self.query?[T.key])
    }
}

protocol QueryInitializable: NodeInitializable {
    
    static var key: String { get }
}


func merge<K: Hashable, V>(keys: [K], with values: [V]) -> [K: V] {
    var dictionary: [K: V] = [:]
    
    zip(keys, values).forEach { key, value in
        dictionary[key] = value
    }
    
    return dictionary
}

struct Expander: QueryInitializable {
    
    static var key: String = "expand"
    
    let expandKeyPaths: [String]
    
    init(node: Node, in context: Context) throws {
        expandKeyPaths = node.string?.components(separatedBy: ",") ?? []
    }
    
    func expand<T: Model>(for models: [T], owner key: String, mappings: @escaping (String, T) throws -> (NodeRepresentable?)) throws -> [Node] {
        return try models.map { (model: T) -> Node in
            var valueMappings = try expandKeyPaths.map { relation in
                return try mappings(relation, model)?.makeNode() ?? Node.null
            }
            
            var keyPaths = expandKeyPaths
            
            keyPaths.append(key)
            try valueMappings.append(model.makeNode())
            
            return try merge(keys: keyPaths, with: valueMappings).makeNode()
        }
    }
}
