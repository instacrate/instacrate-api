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


class BaseViewCollection: EmptyInitializable {
    
    typealias Wrapped = HTTP.Responder
    
    required init() { }
}
