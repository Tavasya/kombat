//
//  RootView.swift
//  kombat
//

import SwiftUI

struct RootView: View {
    @StateObject private var appState = AppState()
    @StateObject private var store = StoreManager()

    /// Once a user is logged in, whether they see Pricing or Main is decided live by
    /// their actual subscription entitlement — not a one-time flag — so the paywall
    /// re-applies immediately if a subscription lapses, and clears immediately on purchase.
    private var effectiveFlow: AppFlow {
        switch appState.flow {
        case .pricing, .main:
            return store.isSubscribed ? .main : .pricing
        case .landing, .onboarding, .auth:
            return appState.flow
        }
    }

    var body: some View {
        Group {
            switch effectiveFlow {
            case .landing:
                LandingView()
            case .onboarding:
                OnboardingView()
            case .auth:
                AuthView()
            case .pricing:
                PricingView()
            case .main:
                MainTabView()
            }
        }
        .environmentObject(appState)
        .environmentObject(store)
        .background(Theme.Colors.background.ignoresSafeArea())
        .onAppear { appState.validateSession() }
    }
}

#Preview {
    RootView()
}
