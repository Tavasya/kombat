//
//  AppState.swift
//  kombat
//

import SwiftUI

enum AppFlow {
    case landing
    case auth
    case onboarding
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
            flow = hasCompletedOnboarding ? .pricing : .onboarding
        }
    }

    /// The SDK restores sessions from the keychain and refreshes tokens on its
    /// own; this just catches the case where the stored session is gone entirely.
    func validateSession() {
        if isLoggedIn && SupabaseService.client.auth.currentSession == nil {
            signOut()
        }
    }

    func beginAuth() {
        withAnimation { flow = .auth }
    }

    func completeAuth(email: String) {
        userEmail = email
        isLoggedIn = true
        withAnimation { flow = .onboarding }
    }

    func completeOnboarding() {
        hasCompletedOnboarding = true
        withAnimation { flow = .pricing }
    }

    func skipOnboarding() {
        completeOnboarding()
    }

    func signOut() {
        Task { try? await SupabaseService.client.auth.signOut() }
        userEmail = ""
        isLoggedIn = false
        withAnimation { flow = .landing }
    }

    /// Permanently deletes the account server-side (via the `delete-account` Edge
    /// Function, which cascades to their scans) and resets all local state.
    func deleteAccount() async throws {
        _ = try await SupabaseService.client.functions.invoke(
            "delete-account",
            options: FunctionInvokeOptions(method: .post)
        )
        userEmail = ""
        isLoggedIn = false
        hasCompletedOnboarding = false
        withAnimation { flow = .landing }
    }
}
