//
//  Relation.swift
//  subber-api
//
//  Created by Hakon Hanesand on 10/16/16.
//
//

import Foundation
import Vapor
import Fluent

protocol Relationable: Model {
    
    associatedtype Relations
    func relations(forFormat format: Format) throws -> Relations
    
    func queryForRelation<R: Relation>(relation: R.Type) throws -> Query<R.Target>
}

protocol Arity {
    
}

struct One: Arity {

}

struct Many: Arity {
    
}

protocol Relation {
    
    associatedtype Target: Relationable
    associatedtype Size: Arity
}

struct AnyRelation<_Input: Relationable, _Size: Arity>: Relation {

    typealias Target = _Input
    typealias Size = _Size
}

protocol RelationNode {
    
    associatedtype Base : Relationable
    associatedtype Rel : Relation
}

extension RelationNode where Rel.Size == Many {
    
    static func run<M : Relationable>(onModel model: M, forFormat format: Format) throws -> [Rel.Target] {
        let query = try model.queryForRelation(relation: Rel.self)
        format.optimize(query: query)
        return try query.run()
    }
}

extension RelationNode where Rel.Size == One {
    
    static func run<M : Relationable>(onModel model: M, forFormat format: Format) throws -> Rel.Target {
        let query = try model.queryForRelation(relation: Rel.self)
        format.optimize(query: query)
        
        guard let first = try query.first() else {
            throw Abort.notFound
        }
        
        return first
    }
}

struct AnyRelationNode<Start : Relationable, Result: Relationable, Size: Arity>: RelationNode {
    
    typealias Base = Start
    typealias Rel = AnyRelation<Result, Size>
}

extension RelationNode where Rel.Size == Many {
    
    static func chain<R: RelationNode>(relation: R.Type, results: [Rel.Target], forFormat format: Format) throws -> [R.Rel.Target] where R.Rel.Size == One {
        var targetModels: [R.Rel.Target] = []
        
        for base in results {
            try targetModels.append(R.run(onModel: base, forFormat: format))
        }
        
        return targetModels
    }
    
    static func chain<R: RelationNode>(relation: R.Type, results: [Rel.Target], forFormat format: Format) throws -> [[R.Rel.Target]] where R.Rel.Size == Many {
        var targetModels: [[R.Rel.Target]] = []
        
        for base in results {
            let a = try R.run(onModel: base, forFormat: format)
            targetModels.append(a)
        }
        
        return targetModels
    }
}

extension Relationable {
    
    func evaluate<A: RelationNode, B: RelationNode>(forFormat format: Format, first: A.Type, second: B.Type) throws -> (A.Rel.Target, B.Rel.Target) where A.Rel.Target == B.Base, A.Rel.Size == One, B.Rel.Size == One {
        let result = try A.run(onModel: self, forFormat: format)
        let b_result = try B.run(onModel: result, forFormat: format)
        
        return (result, b_result)
    }
    
    func evaluate<A: RelationNode, B: RelationNode>(forFormat format: Format, first: A.Type, second: B.Type) throws -> (A.Rel.Target, [B.Rel.Target]) where A.Rel.Target == B.Base, A.Rel.Size == One, B.Rel.Size == Many {
        let result = try A.run(onModel: self, forFormat: format)
        let b_result = try B.run(onModel: result, forFormat: format)
        
        return (result, b_result)
    }
    
    func evaluate<A: RelationNode, B: RelationNode>(forFormat format: Format, first: A.Type, second: B.Type) throws -> ([A.Rel.Target], [B.Rel.Target]) where A.Rel.Target == B.Base, A.Rel.Size == Many, B.Rel.Size == One {
        let result = try A.run(onModel: self, forFormat: format)
        let b_result = try A.chain(relation: B.self, results: result, forFormat: format)
        
        return (result, b_result)
    }

    func evaluate<A: RelationNode, B: RelationNode>(forFormat format: Format, first: A.Type, second: B.Type) throws -> ([A.Rel.Target], [[B.Rel.Target]]) where A.Rel.Target == B.Base, A.Rel.Size == Many, B.Rel.Size == Many {
        let result = try A.run(onModel: self, forFormat: format)
        let b_result = try A.chain(relation: B.self, results: result, forFormat: format)
        
        return (result, b_result)
    }
}
