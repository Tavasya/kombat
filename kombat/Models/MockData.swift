//
//  MockData.swift
//  kombat
//

import Foundation

enum MockData {
    static let onboardingQuestions: [OnboardingQuestion] = [
        OnboardingQuestion(
            icon: "figure.martial.arts",
            question: "What's your experience level?",
            options: ["Beginner", "Intermediate", "Advanced", "Pro"]
        ),
        OnboardingQuestion(
            icon: "calendar",
            question: "How many days a week do you train?",
            options: ["1-2 days", "3-4 days", "5+ days"]
        ),
        OnboardingQuestion(
            icon: "target",
            question: "What's your main goal?",
            options: ["Improve my technique", "Get in fighting shape", "Prepare for competition", "Just for fun"]
        ),
        OnboardingQuestion(
            icon: "figure.boxing",
            question: "What's your primary style?",
            options: ["Boxing", "Muay Thai", "MMA", "Kickboxing", "Other"]
        ),
        OnboardingQuestion(
            icon: "mappin.and.ellipse",
            question: "Where do you train?",
            options: ["At a gym", "At home", "Both"]
        )
    ]

    static let onboardingPages: [OnboardingPage] = [
        OnboardingPage(
            symbolName: "person.2.slash",
            title: "Coach-Level Feedback, On Demand",
            subtitle: "Personal coaching runs $50-100+ an hour. Kombat gives you the same detailed technique breakdown anytime, for a fraction of the cost."
        ),
        OnboardingPage(
            symbolName: "chart.line.uptrend.xyaxis",
            title: "See Every Improvement",
            subtitle: "Most fighters guess if they're getting better. Kombat scores your form after every session, so progress is never a mystery."
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
