//
//  OnboardingQuestion.swift
//  kombat
//

import Foundation

struct OnboardingQuestion: Identifiable {
    let id = UUID()
    let icon: String
    let question: String
    let options: [String]
}
