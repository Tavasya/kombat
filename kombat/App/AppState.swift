//
//  AppState.swift
//  kombat
//

import SwiftUI

enum AppFlow {
    case landing
    case onboarding
    case pricing
    case auth
    case main
}

enum AuthMode {
    case login
    case signUp
}

@MainActor
final class AppState: ObservableObject {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("hasSeenPricing") private var hasSeenPricing = false
    @AppStorage("isLoggedIn") private var isLoggedIn = false

    @Published var flow: AppFlow = .landing
    @Published var authMode: AuthMode = .signUp
    @Published var selectedPlanID: String = "free"

    init() {
        if isLoggedIn {
            flow = .main
        } else if hasSeenPricing {
            flow = .auth
        } else if hasCompletedOnboarding {
            flow = .pricing
        }
    }

    func beginOnboarding() {
        withAnimation { flow = .onboarding }
    }

    func completeOnboarding() {
        hasCompletedOnboarding = true
        withAnimation { flow = .pricing }
    }

    func skipOnboarding() {
        completeOnboarding()
    }

    func selectPricingPlan(_ planID: String) {
        selectedPlanID = planID
        hasSeenPricing = true
        withAnimation { flow = .auth }
    }

    func continueWithFree() {
        selectPricingPlan("free")
    }

    func completeAuth() {
        isLoggedIn = true
        withAnimation { flow = .main }
    }

    /// Jumps straight to Auth for a returning user, marking prior checkpoints complete.
    func skipToAuth() {
        hasCompletedOnboarding = true
        hasSeenPricing = true
        authMode = .login
        withAnimation { flow = .auth }
    }

    func signOut() {
        isLoggedIn = false
        withAnimation { flow = .landing }
    }
}
