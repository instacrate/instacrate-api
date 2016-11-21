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
    
    func create(_ request: Request) throws -> ResponseRepresentable {
        
        guard let box = try Box.find(id: request.query?["box"]?.int) else {
            throw Abort.custom(status: .badRequest, message: "Missing box from request")
        }
        
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
        
        let cloudURL = URL(string: "http://api.instacrate.me/images/")!.appendingPathComponent(name)
        var picture = Picture(url: cloudURL.absoluteString, box_id: box.id!.string!)
        try picture.save()
        
        return try picture.makeJSON()
    }
    
    func makeResource() -> Resource<String> {
        return Resource(
            store: create
        )
    }
}
