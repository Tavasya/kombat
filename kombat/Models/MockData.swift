//
//  MockData.swift
//  kombat
//

import Foundation

enum MockData {
    static let onboardingPages: [OnboardingPage] = [
        OnboardingPage(
            symbolName: "camera.viewfinder",
            title: "AI-Powered Form Analysis",
            subtitle: "Record your strikes and get instant feedback on your technique, just like having a coach in your corner."
        ),
        OnboardingPage(
            symbolName: "chart.line.uptrend.xyaxis",
            title: "Track Your Progress",
            subtitle: "Watch your form score climb session after session with detailed breakdowns by strike type."
        ),
        OnboardingPage(
            symbolName: "figure.martial.arts",
            title: "Train Like a Pro",
            subtitle: "Sharpen your jabs, kicks, and footwork with drills built around your weak points."
        )
    ]

    static let statPoints: [StatPoint] = {
        let now = Date()
        let calendar = Calendar.current
        let scores: [Double] = [58, 61, 65, 63, 70, 74, 79, 76, 82, 85, 83, 88]
        return scores.enumerated().map { index, score in
            StatPoint(date: calendar.date(byAdding: .day, value: -(scores.count - index) * 3, to: now)!, score: score)
        }
    }()

    static let categoryScores: [CategoryScore] = [
        CategoryScore(category: .jabCross, averageScore: 84),
        CategoryScore(category: .roundKick, averageScore: 71),
        CategoryScore(category: .footwork, averageScore: 89),
        CategoryScore(category: .combo, averageScore: 66)
    ]

    static let weeklySessions: [WeeklySessionCount] = [
        WeeklySessionCount(weekLabel: "Wk 1", count: 3),
        WeeklySessionCount(weekLabel: "Wk 2", count: 5),
        WeeklySessionCount(weekLabel: "Wk 3", count: 4),
        WeeklySessionCount(weekLabel: "Wk 4", count: 7)
    ]

    static let userSummary = UserSummary(
        displayName: "Alex",
        streakDays: 6,
        totalSessions: 19,
        averageScore: 79
    )
}
