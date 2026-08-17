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

private let sessionKeychainKey = "session"

@MainActor
final class AppState: ObservableObject {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("isLoggedIn") private(set) var isLoggedIn = false
    @AppStorage("userEmail") private(set) var userEmail = ""

    @Published var flow: AppFlow = .landing

    private var currentAccessToken: String?
    private var currentUserID: String?

    init() {
        if isLoggedIn {
            if let data = KeychainHelper.read(key: sessionKeychainKey),
               let session = try? JSONDecoder().decode(AuthSession.self, from: data) {
                currentAccessToken = session.accessToken
                currentUserID = session.userID
            }
            // Whether the live screen ends up being Pricing or Main is decided by
            // RootView based on real subscription status, not this checkpoint alone.
            flow = .pricing
        } else if hasCompletedOnboarding {
            flow = .auth
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

    func completeAuth(session: AuthSession) {
        if let data = try? JSONEncoder().encode(session) {
            KeychainHelper.save(data, key: sessionKeychainKey)
        }
        userEmail = session.email
        currentAccessToken = session.accessToken
        currentUserID = session.userID
        isLoggedIn = true
        withAnimation { flow = .pricing }

        Task {
            try? await SupabaseDatabaseClient.upsertProfile(
                accessToken: session.accessToken,
                userID: session.userID,
                email: session.email
            )
        }
    }

    /// Mirrors the live StoreKit entitlement into the `profiles` table so it's visible
    /// outside the app (e.g. in the Supabase dashboard), not used to gate access locally.
    func syncSubscriptionStatus(isSubscribed: Bool, productID: String?) async {
        guard let token = currentAccessToken, let userID = currentUserID else { return }
        try? await SupabaseDatabaseClient.upsertProfile(
            accessToken: token,
            userID: userID,
            email: userEmail,
            isSubscribed: isSubscribed,
            productID: productID
        )
    }

    func signOut() {
        KeychainHelper.delete(key: sessionKeychainKey)
        userEmail = ""
        currentAccessToken = nil
        currentUserID = nil
        isLoggedIn = false
        withAnimation { flow = .landing }
    }
}
