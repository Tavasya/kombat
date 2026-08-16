//
//  AuthView.swift
//  kombat
//

import SwiftUI

struct AuthView: View {
    @EnvironmentObject private var appState: AppState

    @State private var fullName = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var password = ""
    @State private var errorMessage: String?

    private var mode: AuthMode { appState.authMode }
    private var isSignUp: Bool { mode == .signUp }

    private var isFormValid: Bool {
        let requiredFieldsFilled = !email.isEmpty && !phone.isEmpty && !password.isEmpty
        return isSignUp ? (requiredFieldsFilled && !fullName.isEmpty) : requiredFieldsFilled
    }

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
                        if isSignUp {
                            AuthTextField(title: "Full Name", text: $fullName, textContentType: .name)
                        }
                        AuthTextField(title: "Email", text: $email, keyboardType: .emailAddress, textContentType: .emailAddress)
                        AuthTextField(title: "Phone Number", text: $phone, keyboardType: .phonePad, textContentType: .telephoneNumber)
                        AuthTextField(title: "Password", text: $password, isSecure: true, textContentType: isSignUp ? .newPassword : .password)
                    }

                    if let errorMessage {
                        Text(errorMessage)
                            .font(Theme.Typography.caption)
                            .foregroundStyle(Theme.Colors.scoreLow)
                    }

                    PrimaryButton(title: isSignUp ? "Create Account" : "Log In") {
                        submit()
                    }

                    TextLinkButton(title: isSignUp ? "Already have an account? Log In" : "Don't have an account? Sign Up") {
                        withAnimation { appState.authMode = isSignUp ? .login : .signUp }
                        errorMessage = nil
                    }
                    .padding(.bottom, Theme.Spacing.lg)
                }
                .padding(.horizontal, Theme.Spacing.xl)
            }
        }
    }

    private var modeToggle: some View {
        HStack(spacing: 4) {
            toggleSegment(title: "Sign Up", isActive: isSignUp) { appState.authMode = .signUp }
            toggleSegment(title: "Log In", isActive: !isSignUp) { appState.authMode = .login }
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
        guard isFormValid else {
            errorMessage = "Please fill in all fields to continue."
            return
        }
        errorMessage = nil
        appState.completeAuth()
    }
}

#Preview {
    AuthView()
        .environmentObject(AppState())
}
