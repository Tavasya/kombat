//
//  PhoneEntryView.swift
//  kombat
//

import SwiftUI

struct PhoneEntryView: View {
    @Binding var path: NavigationPath

    @State private var selectedCountry = Country.default
    @State private var phoneNumber = ""
    @State private var showCountryPicker = false
    @State private var isLoading = false
    @State private var errorMessage: String?

    private var digits: String { phoneNumber.filter(\.isNumber) }
    private var isValid: Bool { digits.count >= 7 }
    private var e164Phone: String { "\(selectedCountry.dialCode)\(digits)" }

    var body: some View {
        ZStack {
            Theme.Colors.background.ignoresSafeArea()

            VStack(spacing: Theme.Spacing.lg) {
                VStack(spacing: Theme.Spacing.xs) {
                    Text("What's Your Number?")
                        .font(Theme.Typography.title)
                        .foregroundStyle(Theme.Colors.textPrimary)
                    Text("We'll text you a code to verify it's you.")
                        .font(Theme.Typography.subheadline)
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, Theme.Spacing.xl)

                HStack(spacing: 0) {
                    Button {
                        showCountryPicker = true
                    } label: {
                        HStack(spacing: 6) {
                            Text(selectedCountry.flag)
                            Text(selectedCountry.dialCode)
                                .foregroundStyle(Theme.Colors.textPrimary)
                            Image(systemName: "chevron.down")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundStyle(Theme.Colors.textSecondary)
                        }
                        .padding(.horizontal, Theme.Spacing.md)
                    }
                    .accessibilityLabel("Country code, \(selectedCountry.name)")

                    Divider()
                        .frame(height: 24)

                    TextField("Phone number", text: $phoneNumber)
                        .keyboardType(.numberPad)
                        .font(Theme.Typography.body)
                        .foregroundStyle(Theme.Colors.textPrimary)
                        .padding(.horizontal, Theme.Spacing.md)
                }
                .padding(.vertical, 12)
                .background(Theme.Colors.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous)
                        .strokeBorder(Theme.Colors.cardBorder, lineWidth: 1)
                )

                if let errorMessage {
                    Text(errorMessage)
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Colors.scoreLow)
                }

                Spacer()

                PrimaryButton(title: isLoading ? "Sending…" : "Continue") {
                    sendCode()
                }
                .disabled(!isValid || isLoading)
                .opacity(isValid ? 1 : 0.5)
                .padding(.bottom, Theme.Spacing.lg)
            }
            .padding(.horizontal, Theme.Spacing.xl)
        }
        .sheet(isPresented: $showCountryPicker) {
            CountryCodePicker(selectedCountry: $selectedCountry)
        }
    }

    private func sendCode() {
        errorMessage = nil
        isLoading = true
        Task {
            do {
                try await SupabaseAuthClient.sendOTP(phone: e164Phone)
                isLoading = false
                path.append(e164Phone)
            } catch {
                isLoading = false
                errorMessage = error.localizedDescription
            }
        }
    }
}

#Preview {
    NavigationStack {
        PhoneEntryView(path: .constant(NavigationPath()))
    }
}
