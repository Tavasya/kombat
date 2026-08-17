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

@MainActor
final class AppState: ObservableObject {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("hasSeenPricing") private var hasSeenPricing = false
    @AppStorage("isLoggedIn") private var isLoggedIn = false
    @AppStorage("userEmail") private(set) var userEmail = ""

    @Published var flow: AppFlow = .landing
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

    /// The SDK restores sessions from the keychain and refreshes tokens on its
    /// own; this just catches the case where the stored session is gone entirely.
    func validateSession() {
        if isLoggedIn && SupabaseService.client.auth.currentSession == nil {
            signOut()
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

    func completeAuth(email: String) {
        userEmail = email
        isLoggedIn = true
        withAnimation { flow = .main }
    }

    func signOut() {
        Task { try? await SupabaseService.client.auth.signOut() }
        userEmail = ""
        isLoggedIn = false
        withAnimation { flow = .landing }
    }
}
