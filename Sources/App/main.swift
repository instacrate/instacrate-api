//
//  Main.swift
//  subber-api
//
//  Created by Hakon Hanesand on 9/26/16.
//
//

import Vapor
import Fluent
import Node

let drop = Droplet.create()

drop.group("box") { box in
    
    box.get(Box.self) { request, box in
        return box.makeJSON()
    }
    
    box.get("category", Category.self) { request, category in
        return try category.boxes().all().makeJSON()
    }
    
    // TODO
    box.get("featured") { request in
        return try JSON(node: .array([]))
    }
    
    // TODO
    box.get("new") { request in
        return try JSON(node: .array([]))
    }
    
    box.get() { request in
        
        guard let ids = request.query?["id"]?.array?.flatMap({ $0.string }) else {
            throw Abort.custom(status: .badRequest, message: "Expected query parameter with name id.")
        }
        
        return try Box.query().filter("id", .in, ids).all().makeJSON()
    }
}


drop.run()
