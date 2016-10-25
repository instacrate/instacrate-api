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

    func process(forFormat format: Format) throws -> Node
    func postProcess(result: inout Node, relations: Relations)
}

protocol Arity {

    associatedtype In: Relationable
    associatedtype Out: NodeConvertible

    static func run(query: Query<In>) throws -> Out

    static func format(results result: Out, withFormat format: Format) throws -> Node
}

struct One<_In: Relationable>: Arity {

    typealias In = _In
    typealias Out = _In

    static func run(query: Query<In>) throws -> Out {
        guard let result = try query.first() else {
            throw Abort.notFound
        }

        return result
    }

    static func format(results result: Out, withFormat format: Format) throws -> Node {
        return try result.process(forFormat: format)
    }
}

// Workaround for the missing conditional conformance supposedly coming later in swift

struct _Container<R: NodeConvertible>: NodeConvertible {

    let array: [R]

    init(node: Node, in context: Context) throws {
        fatalError()
    }

    init(array: [R]) {
        self.array = array
    }

    public func makeNode(context: Context) throws -> Node {
        return try Node( array.map { try $0.makeNode() } )
    }
}

struct Many<_In: Relationable>: Arity {

    typealias In = _In
    typealias Out = _Container<_In>

    static func run(query: Query<In>) throws -> Out {
        return try _Container(array: query.run())
    }

    static func format(results result: Out, withFormat format: Format) throws -> Node {
        return try Node( result.array.map { try $0.process(forFormat: format) } )
    }
}

protocol Relation {
    
    associatedtype Base: Relationable
    associatedtype Target: Relationable
    associatedtype Size: Arity
    
    var name: String { get }

    func evaluate(forEntity entity: Entity, withFormat format: Format) throws -> (Size.Out, Node)
    
    func deriveResult(entity: Entity) throws -> Size.Out
    func process(results: Size.Out, forFormat format: Format) throws -> Node
}

extension Relation {

    func query() throws -> Query<Target> {
        guard let db = Target.database else {
            throw EntityError.noDatabase
        }

        return Query(db)
    }
}

enum Relationship {

    case parent
    case child
    case sibling

    func query<T: Relation>(forRelation relation: T, relationshipKey key: Node?, node: Entity) throws -> Query<T.Target> {

        switch self {
        case .parent:
            return try node.parent(key).makeQuery()

        case .child:
            return try node.children().makeQuery()

        case .sibling:
            return try node.siblings().makeQuery()
        }

    }
}

struct AnyRelation<_In : Relationable, _Out: Relationable, _Size: Arity>: Relation where _Out == _Size.In {

    typealias Base = _In
    typealias Target = _Out
    typealias Size = _Size

    public private(set) var name: String
    private var relationship: Relationship
    
    init(name: String, relationship: Relationship) {
        self.name = name
        self.relationship = relationship
    }

    func evaluate(forEntity entity: Entity, withFormat format: Format) throws -> (Size.Out, Node) {
        let results = try deriveResult(entity: entity)
        let node = try process(results: results, forFormat: format)

        return (results, node)
    }
    
    func deriveResult(entity: Entity) throws -> Size.Out {
        let relationshipKey = Mirror(reflecting: entity).descendant("\(name)_id") as? Node
        let query = try relationship.query(forRelation: self, relationshipKey: relationshipKey, node: entity)
        return try Size.run(query: query)
    }

    func process(results: Size.Out, forFormat format: Format) throws -> Node {
        return try Size.format(results: results, withFormat: format)
    }
}

func construct<A: Relation, B: Relation>(_ a: A, _ b: B, forBase base: A.Base, format: Format) throws -> (Node, A.Size.Out, B.Size.Out) where A.Base == B.Base {
    let (a_result, a_node) = try a.evaluate(forEntity: base, withFormat: format)
    let (b_result, b_node) = try b.evaluate(forEntity: base, withFormat: format)

    let node = try Node(node: [
        a.name : a_node,
        b.name : b_node
    ])

    return (node, a_result, b_result)
}

func construct<A: Relation, B: Relation, C: Relation>(_ a: A, _ b: B, _ c: C, forBase base: A.Base, format: Format) throws -> (Node, A.Size.Out, B.Size.Out, C.Size.Out) where A.Base == B.Base, B.Base == C.Base {
    let (a_result, a_node) = try a.evaluate(forEntity: base, withFormat: format)
    let (b_result, b_node) = try b.evaluate(forEntity: base, withFormat: format)
    let (c_result, c_node) = try c.evaluate(forEntity: base, withFormat: format)

    let node = try Node(node: [
        a.name : a_node,
        b.name : b_node,
        c.name : c_node
    ])

    return (node, a_result, b_result, c_result)
}
