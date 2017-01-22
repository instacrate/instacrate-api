//
//  OnboardingController.swift
//  subber-api
//
//  Created by Hakon Hanesand on 1/22/17.
//
//

import Foundation
import HTTP
import Vapor

final class OnboardingController: ResourceRepresentable {
    
    func create(_ request: Request) throws -> ResponseRepresentable {
        var onboarding: Onboarding = try request.extractModel()
        try onboarding.save()
        return onboarding
    }
    
    func makeResource() -> Resource<String> {
        return Resource(store: create)
    }
}
