//
//  Collection+Tools.swift
//  subber-api
//
//  Created by Hakon Hanesand on 11/18/16.
//
//

import Foundation

extension Collection where Iterator.Element == Int, IndexDistance == Int {
    
    var total: Iterator.Element {
        return reduce(0, +)
    }
    
    var average: Double {
        return isEmpty ? 0 : Double(total) / Double(count)
    }
}
