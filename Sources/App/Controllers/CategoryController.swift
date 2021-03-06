//
//  CategoryController.swift
//  subber-api
//
//  Created by Hakon Hanesand on 11/15/16.
//
//

import Foundation
import Vapor
import HTTP

final class CategoryController: ResourceRepresentable {
    
    // TODO : consider who can create categories
    
    func index(_ request: Request) throws -> ResponseRepresentable {
        return try Category.all().makeJSON()
    }
    
    func show(_ request: Request, category: Category) throws -> ResponseRepresentable {
        return try category.boxes().all().makeJSON()
    }
    
    func create(_ request: Request) throws -> ResponseRepresentable {
        var category: Category = try request.extractModel()
        try category.save()
        return category
    }
    
    func modify(_ request: Request, category: Category) throws -> ResponseRepresentable {
        var category: Category = try request.patchModel(category)
        try category.save()
        return try Response(status: .ok, json: category.makeJSON())
    }
    
    func makeResource() -> Resource<Category> {
        return Resource(
            index: index,
            store: create,
            show: show,
            modify: modify
        )
    }
}
