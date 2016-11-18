//
//  ContractController.swift
//  subber-api
//
//  Created by Hakon Hanesand on 11/17/16.
//
//

import Foundation
import HTTP
import Vapor

final class ContractController: ResourceRepresentable {
    
    func create(_ request: Request) throws -> ResponseRepresentable {
        
        guard let vendor = try Vendor.find(id: request.query?["vendor"]?.int) else {
            throw Abort.custom(status: .badRequest, message: "Missing box from request")
        }

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
    
    func makeResource() -> Resource<String> {
        return Resource()
    }
}
