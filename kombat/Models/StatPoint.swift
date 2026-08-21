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

struct WeeklySessionCount: Identifiable {
    let id = UUID()
    let weekLabel: String
    let count: Int
}
