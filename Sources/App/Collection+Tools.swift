//
//  Collection+Tools.swift
//  subber-api
//
//  Created by Hakon Hanesand on 11/18/16.
//
//

import Foundation

// https://gist.github.com/kristopherjohnson/635e56dcc71842502fcd

/// To use reduce() to sum a sequence, we need
///
/// - a zero (identity) element
/// - an addition operator
protocol Summable {

    /// Identity element for this type and the + operation.
    static var Zero: Self { get }

    /// + operator must be defined for this type
    static func +(lhs: Self, rhs: Self) -> Self
}

extension Sequence where Iterator.Element: Summable {

    /// Return sum of all values in the sequence
    func sum() -> Iterator.Element {
        return self.reduce(Iterator.Element.Zero, +)
    }
}

// Define Zero for Int, Double, and String so we can sum() them.
//
// Extend this to any other types for which you want to use sum().
extension Int: Summable {
    /// The Int value 0
    static var Zero: Int { return 0 }
}

extension Double: Summable {
    /// The Double value 0.0
    static var Zero: Double { return 0.0 }
}

extension String: Summable {
    /// Empty string
    static var Zero: String { return "" }
}


/// A generic mean() function requires that we be able
/// to convert values to Double.
protocol DoubleConvertible {

    /// Return value as Double type
    var doubleValue: Double { get }
}

// Define doubleValue() for Int and Double.
//
// Extend this to any other types for which you want
// to use mean().
extension Int: DoubleConvertible {

    /// Return Int as Double
    var doubleValue: Double { return Double(self) }
}

extension Double: DoubleConvertible {

    /// Return Double value
    var doubleValue: Double { return self }
}

extension Collection where Iterator.Element: DoubleConvertible, Iterator.Element: Summable, IndexDistance: DoubleConvertible {

    /// Return arithmetic mean of values in collection
    func mean() -> Double {
        if (self.count == 0) {
            return 0
        }
        
        return self.sum().doubleValue / self.count.doubleValue
    }
}
