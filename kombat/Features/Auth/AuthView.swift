//
//  AuthView.swift
//  kombat
//

import SwiftUI

private enum AuthMode {
    case signUp
    case login
}

struct AuthView: View {
    @EnvironmentObject private var appState: AppState

    @State private var mode: AuthMode = .signUp
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var infoMessage: String?

    private var isSignUp: Bool { mode == .signUp }
    private var isFormValid: Bool { !email.isEmpty && password.count >= 6 }

    var body: some View {
        ZStack {
            Theme.Colors.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: Theme.Spacing.lg) {
                    VStack(spacing: Theme.Spacing.xs) {
                        Text(isSignUp ? "Create Your Account" : "Welcome Back")
                            .font(Theme.Typography.title)
                            .foregroundStyle(Theme.Colors.textPrimary)
                        Text(isSignUp ? "Start tracking your form today." : "Log in to continue your training.")
                            .font(Theme.Typography.subheadline)
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
                    .padding(.top, Theme.Spacing.xl)

                    modeToggle

                    VStack(spacing: Theme.Spacing.md) {
                        AuthTextField(title: "Email", text: $email, keyboardType: .emailAddress, textContentType: .emailAddress)
                        AuthTextField(title: "Password", text: $password, isSecure: true, textContentType: isSignUp ? .newPassword : .password)
                    }

                    if let infoMessage {
                        Text(infoMessage)
                            .font(Theme.Typography.caption)
                            .foregroundStyle(Theme.Colors.scoreGood)
                            .multilineTextAlignment(.center)
                    }

                    if let errorMessage {
                        Text(errorMessage)
                            .font(Theme.Typography.caption)
                            .foregroundStyle(Theme.Colors.scoreLow)
                            .multilineTextAlignment(.center)
                    }

                    PrimaryButton(title: isLoading ? "Please wait…" : (isSignUp ? "Create Account" : "Log In")) {
                        submit()
                    }
                    .disabled(!isFormValid || isLoading)
                    .opacity(isFormValid ? 1 : 0.5)

                    TextLinkButton(title: isSignUp ? "Already have an account? Log In" : "Don't have an account? Sign Up") {
                        withAnimation { mode = isSignUp ? .login : .signUp }
                        errorMessage = nil
                        infoMessage = nil
                    }
                    .padding(.bottom, Theme.Spacing.lg)
                }
                .padding(.horizontal, Theme.Spacing.xl)
            }
        }
    }

    private var modeToggle: some View {
        HStack(spacing: 4) {
            toggleSegment(title: "Sign Up", isActive: isSignUp) { mode = .signUp }
            toggleSegment(title: "Log In", isActive: !isSignUp) { mode = .login }
        }
        .padding(4)
        .background(Theme.Colors.surface, in: Capsule())
    }

    private func toggleSegment(title: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: { withAnimation { action() } }) {
            Text(title)
                .font(Theme.Typography.subheadline.weight(.semibold))
                .foregroundStyle(isActive ? .white : Theme.Colors.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(isActive ? AnyShapeStyle(Theme.Colors.accentGradient) : AnyShapeStyle(Color.clear), in: Capsule())
        }
    }

    private func submit() {
        errorMessage = nil
        infoMessage = nil
        isLoading = true
        Task {
            do {
                if isSignUp {
                    let response = try await SupabaseService.client.auth.signUp(email: email, password: password)
                    if response.session != nil {
                        appState.completeAuth(email: email)
                    } else {
                        // "Confirm email" is on, so no session until the link is clicked.
                        isLoading = false
                        infoMessage = "Check your email to confirm your account, then log in."
                        withAnimation { mode = .login }
                    }
                } else {
                    _ = try await SupabaseService.client.auth.signIn(email: email, password: password)
                    appState.completeAuth(email: email)
                }
            } catch {
                isLoading = false
                errorMessage = error.localizedDescription
            }
        }
    }
}

#Preview {
    AuthView()
        .environmentObject(AppState())
}
