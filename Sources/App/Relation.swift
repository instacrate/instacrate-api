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

    func relations() throws -> Relations
}
