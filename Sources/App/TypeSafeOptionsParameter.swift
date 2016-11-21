//
//  TypeSafeOptionsParameter.swift
//  subber-api
//
//  Created by Hakon Hanesand on 11/18/16.
//
//

import Foundation
import Vapor
import HTTP

import TypeSafeRouting
import Node
import Fluent
import Vapor
import HTTP

extension Query {
    
    func apply(_ option: QueryModifiable) -> Query<T> {
        return option.modify(self)
    }
}

protocol QueryModifiable {
    
    func modify<T: Entity>(_ query: Query<T>) -> Query<T>
}

protocol TypesafeOptionsParameter: StringInitializable, NodeConvertible, QueryModifiable {
    
    static var key: String { get }
    static var values: [String] { get }
}

extension TypesafeOptionsParameter {
    
    static var humanReadableValuesString: String {
        return "Valid values are : [\(Self.values.joined(separator: ", "))]"
    }
    
    func modify<T : Entity>(_ query: Query<T>) -> Query<T> {
        return query
    }
}

extension RawRepresentable where RawValue == String {
    
    public init?(from string: String) throws {
        self.init(rawValue: string)
    }
    
    public init?(from _string: String?) throws {
        guard let string = _string else {
            return nil
        }
        
        self.init(rawValue: string)
    }
    
    init(node: Node, in context: Context = EmptyNode) throws {
        guard let string = node.string else {
            throw NodeError.unableToConvert(node: node, expected: "\(String.self)")
        }
        
        guard let value = Self.init(rawValue: string) else {
            
            let message: String = (Self.self as? TypesafeOptionsParameter.Type)?.humanReadableValuesString ?? ""
            throw Abort.custom(status: .badRequest, message: "Invalid value for enumerated type. \(message)")
        }
        
        self = value
    }
    
    func makeNode(context: Context = EmptyNode) throws -> Node {
        return Node.string(self.rawValue)
    }
}

extension Request {
    
    func extract<T: TypesafeOptionsParameter>() throws -> T where T: RawRepresentable, T.RawValue == String {
        return try T.init(node: self.query?[T.key])
    }
}
