//
//  CreationCollection.swift
//  subber-api
//
//  Created by Hakon Hanesand on 10/19/16.
//
//

import Foundation
import Vapor
import HTTP
import Routing
import JSON
import Auth

extension Message {
    
    public func json() throws -> JSON {
        if let existing = storage["json"] as? JSON {
            return existing
        } else if let type = headers["Content-Type"], type.contains("application/json") {
            guard case let .data(body) = body else { throw Abort.custom(status: .badRequest, message: "Unable to decode body.") }
            let json = try JSON(bytes: body)
            storage["json"] = json
            return json
        } else {
            throw Abort.custom(status: .badRequest, message: "Missing application/json Content-Type.")
        }
    }
}

final class CreationCollection : RouteCollection, EmptyInitializable {
    
    init () {}
    
    typealias Wrapped = HTTP.Responder

    func build<Builder : RouteBuilder>(_ builder: Builder) where Builder.Value == Responder {
        
        let upload = builder.grouped("upload")
        
        
        
        upload.post("contract", Vendor.self) { request, vendor in
            guard let fileData = request.multipart?["contract"]?.file?.data else {
                throw Abort.custom(status: .badRequest, message: "No file in request")
            }
            
            guard let workPath = Droplet.instance?.workDir else {
                throw Abort.custom(status: .internalServerError, message: "Missing working directory")
            }
            
            let name = "\(vendor.parentCompanyName)_\(UUID().uuidString).txt"
            let imageFolder = "Private/Contracts/"
            let saveURL = URL(fileURLWithPath: workPath).appendingPathComponent(imageFolder, isDirectory: true).appendingPathComponent(name, isDirectory: false)
            
            do {
                let data = Data(bytes: fileData)
                try data.write(to: saveURL)
            } catch {
                throw Abort.custom(status: .internalServerError, message: "Unable to write multipart form data to file. Underlying error \(error)")
            }
            
            return Response(status: .created)
        }
    }
}
