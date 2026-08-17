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

private let sessionKeychainKey = "session"

@MainActor
final class AppState: ObservableObject {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("hasSeenPricing") private var hasSeenPricing = false
    @AppStorage("isLoggedIn") private var isLoggedIn = false
    @AppStorage("userPhoneNumber") private(set) var userPhoneNumber = ""

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

    func completeAuth(session: AuthSession) {
        if let data = try? JSONEncoder().encode(session) {
            KeychainHelper.save(data, key: sessionKeychainKey)
        }
        userPhoneNumber = session.phone
        isLoggedIn = true
        withAnimation { flow = .main }
    }

    func signOut() {
        KeychainHelper.delete(key: sessionKeychainKey)
        userPhoneNumber = ""
        isLoggedIn = false
        withAnimation { flow = .landing }
    }
}
