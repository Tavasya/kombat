//
//  PricingPlan.swift
//  kombat
//

import Foundation

struct PricingPlan: Identifiable, Equatable {
    let id: String
    let name: String
    let priceText: String
    let billingPeriodText: String?
    let features: [String]
    let isRecommended: Bool
}
