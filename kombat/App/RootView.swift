//
//  RootView.swift
//  kombat
//

import SwiftUI

struct RootView: View {
    @StateObject private var appState = AppState()

    var body: some View {
        Group {
            switch appState.flow {
            case .landing:
                LandingView()
            case .onboarding:
                OnboardingView()
            case .pricing:
                PricingView()
            case .auth:
                AuthView()
            case .main:
                MainTabView()
            }
        }
        .environmentObject(appState)
        .background(Theme.Colors.background.ignoresSafeArea())
        .onAppear { appState.validateSession() }
    }
}

#Preview {
    RootView()
}
