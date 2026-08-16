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

    static let pricingPlans: [PricingPlan] = [
        PricingPlan(
            id: "free",
            name: "Free",
            priceText: "$0",
            billingPeriodText: nil,
            features: ["3 scans per month", "Basic form scoring", "7-day history"],
            isRecommended: false
        ),
        PricingPlan(
            id: "monthly",
            name: "Monthly",
            priceText: "$14.99",
            billingPeriodText: "per month",
            features: ["Unlimited scans", "Full form breakdown", "Unlimited history", "Progress trends"],
            isRecommended: false
        ),
        PricingPlan(
            id: "annual",
            name: "Annual",
            priceText: "$89.99",
            billingPeriodText: "per year — save 50%",
            features: ["Everything in Monthly", "Priority scan processing", "Personalized drills"],
            isRecommended: true
        )
    ]

    static let scanSessions: [ScanSession] = {
        let now = Date()
        let calendar = Calendar.current
        return [
            ScanSession(date: calendar.date(byAdding: .hour, value: -5, to: now)!, category: .jabCross, formScore: 88, durationSeconds: 95),
            ScanSession(date: calendar.date(byAdding: .day, value: -1, to: now)!, category: .roundKick, formScore: 74, durationSeconds: 122),
            ScanSession(date: calendar.date(byAdding: .day, value: -2, to: now)!, category: .footwork, formScore: 91, durationSeconds: 80),
            ScanSession(date: calendar.date(byAdding: .day, value: -4, to: now)!, category: .combo, formScore: 62, durationSeconds: 140),
            ScanSession(date: calendar.date(byAdding: .day, value: -6, to: now)!, category: .jabCross, formScore: 79, durationSeconds: 101)
        ]
    }()

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
