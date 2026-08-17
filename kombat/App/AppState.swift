//
//  AppState.swift
//  kombat
//

import SwiftUI

enum AppFlow {
    case landing
    case onboarding
    case auth
    case pricing
    case main
}

@MainActor
final class AppState: ObservableObject {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("isLoggedIn") private(set) var isLoggedIn = false
    @AppStorage("userEmail") private(set) var userEmail = ""

    @Published var flow: AppFlow = .landing

    init() {
        if isLoggedIn {
            // Whether the live screen ends up being Pricing or Main is decided by
            // RootView based on real subscription status, not this checkpoint alone.
            flow = .pricing
        } else if hasCompletedOnboarding {
            flow = .auth
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
        withAnimation { flow = .auth }
    }

    func skipOnboarding() {
        completeOnboarding()
    }

    func completeAuth(email: String) {
        userEmail = email
        isLoggedIn = true
        withAnimation { flow = .pricing }

        Task {
            try? await SupabaseDatabaseClient.upsertProfile(email: email)
        }
    }

    /// Mirrors the live StoreKit entitlement into the `profiles` table so it's visible
    /// outside the app (e.g. in the Supabase dashboard), not used to gate access locally.
    func syncSubscriptionStatus(isSubscribed: Bool, productID: String?) async {
        guard isLoggedIn else { return }
        try? await SupabaseDatabaseClient.upsertProfile(
            email: userEmail,
            isSubscribed: isSubscribed,
            productID: productID
        )
    }

    func signOut() {
        Task { try? await SupabaseService.client.auth.signOut() }
        userEmail = ""
        isLoggedIn = false
        withAnimation { flow = .landing }
    }
}
