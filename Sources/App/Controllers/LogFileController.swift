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
        
        guard let files = request.multipart else {
            throw Abort.custom(status: .badRequest, message: "No files in request")
        }
        
        drop.console.info("files \(files)")
        
        guard let workPath = Droplet.instance?.workDir else {
            throw Abort.custom(status: .internalServerError, message: "Missing working directory")
        }
        
        guard let description = request.json?["description"]?.string else {
            throw Abort.custom(status: .badRequest, message: "No file description")
        }
        
        let folder = "Private/Logs/\(description)"
        let saveFolder = URL(fileURLWithPath: workPath).appendingPathComponent(folder, isDirectory: true)
        
        for (name, multipart) in files {
            do {
                if case let .file(file) = multipart {
                    guard let fileName = file.name else {
                        throw Abort.custom(status: .badRequest, message: "Missing file name for \(name)")
                    }
                    
                    guard fileName.hasSuffix(".log") else {
                        throw Abort.custom(status: .badRequest, message: "Missing file extension for \(name)")
                    }
                    
                    let saveURL = saveFolder.appendingPathComponent(fileName, isDirectory: false)
                    
                    let data = Data(bytes: file.data)
                    try data.write(to: saveURL)
                } else {
                    drop.console.info("wrong type")
                }
            } catch {
                throw Abort.custom(status: .internalServerError, message: "Unable to write multipart form data to file. Underlying error \(error)")
            }
        }

        return Response(status: .created)
    }
    
    func makeResource() -> Resource<String> {
        return Resource(store: create)
    }
}
