//
//  StripeCard.swift
//  subber-api
//
//  Created by Hakon Hanesand on 12/2/16.
//
//

import Foundation
import Vapor

extension RawRepresentable where Self: NodeInitializable, RawValue == String {
    
    init(node: Node, in context: Context = EmptyNode) throws {
        
        guard let string = node.string else {
            throw NodeError.unableToConvert(node: node, expected: "\(String.self)")
        }
        
        guard let value = Self.init(rawValue: string) else {
            throw Abort.custom(status: .badRequest, message: "Invalid value for enumerated type.")
        }
        
        self = value
    }
    
    func makeNode(context: Context = EmptyNode) throws -> Node {
        return Node.string(self.rawValue)
    }
}

enum Verification: String, NodeConvertible {
    
    case pass
    case fail
    case unavailable
    case unchecked
}

enum Brand: String, NodeConvertible {
    
    case visa = "Visa"
    case americanExpress = "American Express"
    case masterCard = "MasterCard"
    case discover = "Discover"
    case jcb = "JCB"
    case dinerClub = "Diners Club"
    case unknwon = "Unknown"
}

enum Funding: String, NodeConvertible {

    case credit
    case debit
    case prepaid
    case unknown
}

enum TokenizationMethod: String, NodeConvertible {
    
    case applePay = "apple_pay"
    case androidPay = "android_pay"
}

final class StripeCard: NodeConvertible {
    
    static let type = "card"
    
    let address_city: String
    let address_county: String
    
    let address_line1: String
    let address_line2: String
    let address_line1_check: Verification
    
    let address_state: String
    
    let address_zip: String
    let address_zip_check: Verification
    
    let brand: Brand
    
    // TODO : to enum
    let county: String
    
    let currency: String?
    let customer: String
    
    let cvc_check: Verification
    let default_for_currency: Bool?
    
    let dynamic_last4: String?
    let last4: String
    
    let exp_year: Int
    let exp_month: Int
    
    let fingerprint: String
    
    let funding: Funding
    let name: String
    
    let recipient: String
    
    let tokenization_method: TokenizationMethod?
    
    init(node: Node, in context: Context = EmptyNode) throws {
       
        guard try node.extract("object") == StripeCard.type else {
            throw Abort.custom(status: .internalServerError, message: "Incorrect object type.")
        }
        
        address_city = try node.extract("address_city")
        address_county = try node.extract("address_county")
        address_line1 = try node.extract("address_line1")
        address_line2 = try node.extract("address_line2")
        address_line1_check = try node.extract("address_line1_check")
        address_state = try node.extract("address_state")
        address_zip = try node.extract("address_zip")
        address_zip_check = try node.extract("address_zip_check")
        brand = try node.extract("brand")
        county = try node.extract("county")
        currency = try? node.extract("currency")
        customer = try node.extract("customer")
        cvc_check = try node.extract("cvc_check")
        default_for_currency = try? node.extract("default_for_currency")
        dynamic_last4 = try? node.extract("dynamic_last4")
        last4 = try node.extract("last4")
        exp_year = try node.extract("exp_year")
        exp_month = try node.extract("exp_month")
        fingerprint = try node.extract("fingerprint")
        funding = try node.extract("funding")
        name = try node.extract("name")
        recipient = try node.extract("recipient")
        tokenization_method = try? node.extract("tokenization_method")
    }
    
    func makeNode(context: Context = EmptyNode) throws -> Node {
        return try Node(node : [
            "address_city" : .string(address_city),
            "address_county" : .string(address_county),
            "address_line1" : .string(address_line1),
            "address_line2" : .string(address_line2),
            "address_line1_check" : .string(address_line1_check.rawValue),
            "address_state" : .string(address_state),
            "address_zip" : .string(address_zip),
            "address_zip_check" : .string(address_zip_check.rawValue),
            "brand" : .string(brand.rawValue),
            "county" : .string(county),
            
            "customer" : .string(customer),
            "cvc_check" : .string(cvc_check.rawValue),
            
            
            "last4" : .string(last4),
            "exp_year" : .number(.int(exp_year)),
            "exp_month" : .number(.int(exp_month)),
            "fingerprint" : .string(fingerprint),
            "funding" : .string(funding.rawValue),
            "name" : .string(name),
            "recipient" : .string(recipient),
            
        ] as [String : Node]).add(objects: ["currency" : currency,
                                            "default_for_currency" : default_for_currency,
                                        "dynamic_last4" : dynamic_last4,
                                "tokenization_method" : tokenization_method])
    }
}
