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
    
    private let allowedModels: [String : (JSONInitializable & Model).Type] = ["\(User.self)" : User.self,
                                                                              "\(Vendor.self)" : Vendor.self,
                                                                              "\(Review.self)" : Review.self,
                                                                              "\(Category.self)" : Category.self]
    
    func build<Builder : RouteBuilder>(_ builder: Builder) where Builder.Value == Responder {
        
        let create = builder.grouped("create")
        
        create.post(String.self) { request, table in

            guard let type = self.allowedModels[table] else {
                throw Abort.custom(status: .badRequest, message: "Table \(table) is not allowed for creation API. Acceptable values are \(self.allowedModels.keys.values)")
            }
            
            let json = try request.json()
            var instance = try type.init(json: json)
            try instance.save()
            
            return Response(status: .created)
        }
        
        let upload = builder.grouped("image").grouped(drop.protect())
        
        upload.post("upload", Box.self) { request, box in
            guard let fileData = request.multipart?["image"]?.file?.data else {
                throw Abort.custom(status: .badRequest, message: "No file in request")
            }
            
            guard let workPath = Droplet.instance?.workDir else {
                throw Abort.custom(status: .internalServerError, message: "Missing working directory")
            }
        
            let name = UUID().uuidString + ".png"
            let imageFolder = "Public/images"
            let saveURL = URL(fileURLWithPath: workPath).appendingPathComponent(imageFolder, isDirectory: true).appendingPathComponent(name, isDirectory: false)
            
            do {
                let data = Data(bytes: fileData)
                try data.write(to: saveURL)
            } catch {
                throw Abort.custom(status: .internalServerError, message: "Unable to write multipart form data to file. Underlying error \(error)")
            }
            
            var picture = Picture(url: saveURL.absoluteString, box_id: box.id!.string!)
            try picture.save()
            
            return try picture.makeJSON()
        }
    }
}
