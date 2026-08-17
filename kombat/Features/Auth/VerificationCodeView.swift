//
//  VerificationCodeView.swift
//  kombat
//

import SwiftUI

struct VerificationCodeView: View {
    let phone: String

    @EnvironmentObject private var appState: AppState
    @FocusState private var isFocused: Bool

    @State private var code = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var isResending = false

    private let codeLength = 6

    var body: some View {
        ZStack {
            Theme.Colors.background.ignoresSafeArea()

            VStack(spacing: Theme.Spacing.lg) {
                VStack(spacing: Theme.Spacing.xs) {
                    Text("Enter Your Code")
                        .font(Theme.Typography.title)
                        .foregroundStyle(Theme.Colors.textPrimary)
                    Text("We sent a 6-digit code to \(phone)")
                        .font(Theme.Typography.subheadline)
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, Theme.Spacing.xl)

                codeBoxes
                    .onTapGesture { isFocused = true }

                if let errorMessage {
                    Text(errorMessage)
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Colors.scoreLow)
                }

                Button {
                    resendCode()
                } label: {
                    Text(isResending ? "Sending…" : "Didn't get it? Resend Code")
                        .font(Theme.Typography.subheadline)
                        .foregroundStyle(Theme.Colors.accent)
                }
                .disabled(isResending)

                Spacer()

                PrimaryButton(title: isLoading ? "Verifying…" : "Verify") {
                    verifyCode()
                }
                .disabled(code.count != codeLength || isLoading)
                .opacity(code.count == codeLength ? 1 : 0.5)
                .padding(.bottom, Theme.Spacing.lg)
            }
            .padding(.horizontal, Theme.Spacing.xl)
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { isFocused = true }
    }

    private var codeBoxes: some View {
        ZStack {
            // Hidden field drives actual text input and keyboard.
            TextField("", text: $code)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .focused($isFocused)
                .opacity(0.01)
                .onChange(of: code) { _, newValue in
                    code = String(newValue.filter(\.isNumber).prefix(codeLength))
                }

            HStack(spacing: Theme.Spacing.sm) {
                ForEach(0..<codeLength, id: \.self) { index in
                    let filled = index < code.count
                    Text(filled ? String(Array(code)[index]) : "")
                        .font(Theme.Typography.title)
                        .foregroundStyle(Theme.Colors.textPrimary)
                        .frame(width: 44, height: 56)
                        .background(Theme.Colors.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous)
                                .strokeBorder(filled ? Theme.Colors.accent : Theme.Colors.cardBorder, lineWidth: filled ? 2 : 1)
                        )
                }
            }
            .allowsHitTesting(false)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Verification code")
        .accessibilityValue(code.isEmpty ? "Empty" : code)
    }

    private func verifyCode() {
        errorMessage = nil
        isLoading = true
        Task {
            do {
                let session = try await SupabaseAuthClient.verifyOTP(phone: phone, code: code)
                isLoading = false
                appState.completeAuth(session: session)
            } catch {
                isLoading = false
                errorMessage = error.localizedDescription
            }
        }
    }

    private func resendCode() {
        isResending = true
        errorMessage = nil
        Task {
            do {
                try await SupabaseAuthClient.sendOTP(phone: phone)
            } catch {
                errorMessage = error.localizedDescription
            }
            isResending = false
        }
    }
}

#Preview {
    NavigationStack {
        VerificationCodeView(phone: "+15555550123")
            .environmentObject(AppState())
    }
}
