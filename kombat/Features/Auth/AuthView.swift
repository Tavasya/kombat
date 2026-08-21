//
//  AuthView.swift
//  kombat
//

import AuthenticationServices
import CryptoKit
import SwiftUI

private enum AuthMode {
    case signUp
    case login
}

struct AuthView: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) private var colorScheme

    @State private var mode: AuthMode = .signUp
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var infoMessage: String?
    @State private var currentAppleNonce: String?

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

                    signInWithAppleButton

                    HStack(spacing: Theme.Spacing.sm) {
                        Rectangle().fill(Theme.Colors.cardBorder).frame(height: 1)
                        Text("or")
                            .font(Theme.Typography.caption)
                            .foregroundStyle(Theme.Colors.textTertiary)
                        Rectangle().fill(Theme.Colors.cardBorder).frame(height: 1)
                    }

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

    private var signInWithAppleButton: some View {
        SignInWithAppleButton(.continue) { request in
            let nonce = Self.randomNonceString()
            currentAppleNonce = nonce
            request.requestedScopes = [.email, .fullName]
            request.nonce = Self.sha256(nonce)
        } onCompletion: { result in
            handleAppleCompletion(result)
        }
        .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
        .frame(height: 50)
        .clipShape(Capsule())
    }

    private func handleAppleCompletion(_ result: Result<ASAuthorization, Error>) {
        errorMessage = nil
        infoMessage = nil

        switch result {
        case .failure(let error):
            // User cancelling the sheet shouldn't read as an error.
            if (error as? ASAuthorizationError)?.code == .canceled { return }
            errorMessage = error.localizedDescription

        case .success(let authorization):
            guard
                let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
                let identityTokenData = credential.identityToken,
                let idToken = String(data: identityTokenData, encoding: .utf8),
                let nonce = currentAppleNonce
            else {
                errorMessage = "Couldn't complete Sign in with Apple."
                return
            }

            isLoading = true
            Task {
                do {
                    let session = try await SupabaseService.client.auth.signInWithIdToken(
                        credentials: .init(provider: .apple, idToken: idToken, nonce: nonce)
                    )
                    appState.completeAuth(email: session.user.email ?? "")
                } catch {
                    isLoading = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    private static func randomNonceString(length: Int = 32) -> String {
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length

        while remainingLength > 0 {
            var randomBytes = [UInt8](repeating: 0, count: 16)
            let status = SecRandomCopyBytes(kSecRandomDefault, randomBytes.count, &randomBytes)
            precondition(status == errSecSuccess, "Unable to generate nonce.")

            for byte in randomBytes where remainingLength > 0 {
                if byte < charset.count {
                    result.append(charset[Int(byte)])
                    remainingLength -= 1
                }
            }
        }
        return result
    }

    private static func sha256(_ input: String) -> String {
        SHA256.hash(data: Data(input.utf8))
            .compactMap { String(format: "%02x", $0) }
            .joined()
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
