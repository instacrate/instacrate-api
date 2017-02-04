//
//  ImageController.swift
//  subber-api
//
//  Created by Hakon Hanesand on 11/17/16.
//
//

import Foundation
import HTTP
import Vapor

final class ImageController: ResourceRepresentable {
    
    // TODO : Better handling of images, allow all images to be stored in one request
    
    func create(_ request: Request) throws -> ResponseRepresentable {
        
        guard let box = try Box.find(id: request.query?["box"]?.int) else {
            throw Abort.custom(status: .badRequest, message: "Missing box from request")
        }
        
        guard let fileData = request.multipart?["image"]?.file?.data else {
            throw Abort.custom(status: .badRequest, message: "No file in request")
        }

        let url = try save(data: Data(bytes: fileData))
        
        var picture = Picture(url: url, box_id: box.id!.string!)
        try picture.save()
        
        return try picture.makeJSON()
    }
    
    func modify(_ request: Request, _picture: Picture) throws -> ResponseRepresentable {
        
        var picture = _picture
        
        guard let urlString = try request.json().node["url"]?.string else {
            throw Abort.custom(status: .badRequest, message: "Missing url from json body.")
        }
        
        guard let bytes = try drop.client.get(urlString).body.bytes else {
            throw Abort.custom(status: .internalServerError, message: "No bytes in body")
        }
        
        let path = try save(data: Data(bytes: bytes), overriding: picture)
        picture.url = path
        try picture.save()
        
        return try picture.makeJSON()
    }
    
    func save(data: Data, overriding picture: Picture? = nil) throws -> String {
    
        let imageFolder = "Public/images"
        
        guard let workPath = Droplet.instance?.workDir else {
            throw Abort.custom(status: .internalServerError, message: "Missing working directory")
        }
        
        let name = picture == nil ? UUID().uuidString + ".png" : URL(string: picture!.url)!.lastPathComponent
        let saveURL = URL(fileURLWithPath: workPath).appendingPathComponent(imageFolder, isDirectory: true).appendingPathComponent(name, isDirectory: false)
        
        do {
            try data.write(to: saveURL)
        } catch {
            throw Abort.custom(status: .internalServerError, message: "Unable to write multipart form data to file. Underlying error \(error)")
        }
        
        return "http://api.instacrate.me/images/" + name
    }
    
    func makeResource() -> Resource<Picture> {
        return Resource(
            store: create,
            modify: modify
        )
    }
}
