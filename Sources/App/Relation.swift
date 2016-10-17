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

protocol Relation {
    
    associatedtype Input: Model
    associatedtype QueryOutput: Model
    associatedtype Output
    
    static func execute(query: Query<Input>) throws -> Output
}

struct AnyRelation<_Input: Model, _QueryOutput: Model, _Output>: Relation {

    typealias Input = _Input
    typealias QueryOutput = _QueryOutput
    typealias Output = _Output
    
    static func execute(query: Query<_Input>) throws -> _Output {
        return try self.execute(query: query)
    }
}

struct SingularRelation<Type: Model>: Relation {
    
    typealias Output = Type
    typealias QueryOutput = Type
    typealias Input = Type

    static func execute(query: Query<Type>) throws -> Type {
        guard let result = try query.first() else {
            throw Abort.notFound
        }
        
        return result
    }
}

struct ManyRelation<Type: Model>: Relation {
    
    typealias Input = Type
    typealias QueryOutput = Type
    typealias Output = [Type]
    
    static func execute(query: Query<Input>) throws -> Output {
        return try query.run()
    }
}

protocol Relationable: Model {
        
    associatedtype Relations
    func relations(forFormat format: Format) throws -> Relations
    
    func queryForRelation<R: Relation>(relation: R.Type) throws -> Query<R.Input>
    
//    func evaluate
}

protocol RelationNode {
    
    associatedtype Base : Model
    associatedtype Next : Relation
}

struct AnyRelationNode<L : Relationable, R : Relation>: RelationNode {
    
    typealias Base = L
    typealias Next = R
    
    static func run(withFormat format: Format, model: Base) throws -> Next.Output {
        let query: Query<R.Input> = try model.queryForRelation(relation: R.self)
        format.optimize(query: query)
        return try R.execute(query: query)
    }
}

struct RelationChain<L : RelationNode, R : RelationNode> where L.Next.QueryOutput == R.Base { }

infix operator =>: AdditionPrecedence

extension RelationNode {
    
    static func =><R: RelationNode>(lhs: Self.Type, rhs: R.Type) -> RelationChain<Self, R>.Type where Self.Next.QueryOutput == R.Base {
        return RelationChain<Self, R>.self
    }
}
