//
//  LogFileController.swift
//  subber-api
//
//  Created by Hakon Hanesand on 12/6/16.
//
//

import Foundation
import HTTP
import Vapor

final class LogFileController: ResourceRepresentable {
    
    func create(_ request: Request) throws -> ResponseRepresentable {
        
        guard let fileData = request.multipart?["log"]?.file?.data else {
            throw Abort.custom(status: .badRequest, message: "No file in request")
        }
        
        guard let workPath = Droplet.instance?.workDir else {
            throw Abort.custom(status: .internalServerError, message: "Missing working directory")
        }
        
        guard let description = request.query?["description"]?.string else {
            throw Abort.custom(status: .badRequest, message: "No file description")
        }
        
        let name = "\(UUID().uuidString)-\(description).txt"
        let imageFolder = "Private/Logs"
        let saveURL = URL(fileURLWithPath: workPath).appendingPathComponent(imageFolder, isDirectory: true).appendingPathComponent(name, isDirectory: false)
        
        do {
            let data = Data(bytes: fileData)
            try data.write(to: saveURL)
        } catch {
            throw Abort.custom(status: .internalServerError, message: "Unable to write multipart form data to file. Underlying error \(error)")
        }
        
        return Response(status: .created)
    }
    
    func makeResource() -> Resource<String> {
        return Resource(store: create)
    }
}
