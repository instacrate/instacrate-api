//
//  HTTPClient.swift
//  subber-api
//
//  Created by Hakon Hanesand on 1/19/17.
//
//

import Foundation
import JSON
import HTTP
import Transport
import Vapor

func createToken(token: String) -> [HeaderKey: String] {
    let data = token.data(using: .utf8)!.base64EncodedString()
    return ["Authorization" : "Basic \(data)"]
}

public class HTTPClient {
    
    let baseURLString: String
    let client: Client<TCPClientStream, Serializer<Request>, Parser<Response>>.Type
    
    init(urlString: String) {
        baseURLString = urlString
        
        client = Client<TCPClientStream, Serializer<Request>, Parser<Response>>.self
    }
    
    func get<T: NodeConvertible>(_ resource: String, query: [String : CustomStringConvertible] = [:], token: String = Stripe.token) throws -> T {
        let response = try client.get(baseURLString + resource, headers: createToken(token: token), query: query)
        
        guard let json = try? response.json() else {
            throw Abort.custom(status: .internalServerError, message: response.description)
        }
        
        try checkForStripeError(in: json)
        
        return try T.init(node: json.makeNode())
    }
    
    func get<T: NodeConvertible>(_ resource: String, query: [String : CustomStringConvertible] = [:], token: String = Stripe.token) throws -> [T] {
        let response = try client.get(baseURLString + resource, headers: createToken(token: token), query: query)
        
        guard let json = try? response.json() else {
            throw Abort.custom(status: .internalServerError, message: response.description)
        }
        
        try checkForStripeError(in: json)
        
        guard let objects = json.node["data"]?.nodeArray else {
            throw Abort.custom(status: .internalServerError, message: "Unexpected response formatting. \(json)")
        }
        
        return try objects.map {
            return try T.init(node: $0)
        }
    }
    
    func post<T: NodeConvertible>(_ resource: String, query: [String : CustomStringConvertible] = [:], token: String = Stripe.token) throws -> T {
        let response = try client.post(baseURLString + resource, headers: createToken(token: token), query: query)
        
        guard let json = try? response.json() else {
            throw Abort.custom(status: .internalServerError, message: response.description)
        }
        
        try checkForStripeError(in: json)
        
        return try T.init(node: json.makeNode())
    }
    
    func upload<T: NodeConvertible>(_ resource: String, query: [String: CustomStringConvertible] = [:], multipart: Multipart) throws -> T {
        let boundry = "\(UUID().uuidString)-boundary-\(UUID().uuidString)"
        let data = try multipart.serialized(boundary: boundry, keyName: "file")
        
        let response = try client.post(baseURLString + resource, headers: [.contentType : "multipart/form-data"], body: Body.data(data))
        
        guard let json = try? response.json() else {
            throw Abort.custom(status: .internalServerError, message: response.description)
        }
        
        try checkForStripeError(in: json)
        
        return try T.init(node: json.makeNode())
    }
    
    func delete(_ resource: String, query: [String : CustomStringConvertible] = [:], token: String = Stripe.token) throws -> JSON {
        let response = try client.delete(baseURLString + resource, headers: createToken(token: token), query: query)
        
        guard let json = try? response.json() else {
            throw Abort.custom(status: .internalServerError, message: response.description)
        }
        
        try checkForStripeError(in: json)
        
        return json
    }
    
    private func checkForStripeError(in json: JSON) throws {
        if let error = json.node["error"]?.nodeObject {
            
            guard let type = error["type"]?.string else {
                throw Abort.custom(status: .internalServerError, message: "Unknown error recieved from Stripe.")
            }
            
            guard let message = error["message"]?.string else {
                throw Abort.custom(status: .internalServerError, message: "Unknown error of type \(type) recieved from Stripe.")
            }
            
            throw StripeError.error(type: type, message: message)
        }
    }
}
