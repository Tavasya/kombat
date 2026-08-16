//
//  StatPoint.swift
//  kombat
//

import Foundation

struct StatPoint: Identifiable {
    let id = UUID()
    let date: Date
    let score: Double
}

struct CategoryScore: Identifiable {
    let id = UUID()
    let category: StrikeCategory
    let averageScore: Double
}

struct WeeklySessionCount: Identifiable {
    let id = UUID()
    let weekLabel: String
    let count: Int
}
