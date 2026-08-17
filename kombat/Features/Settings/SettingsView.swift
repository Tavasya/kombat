//
//  SettingsView.swift
//  kombat
//

import StoreKit
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState

    @State private var showManageSubscriptions = false
    @State private var showDeleteConfirmation = false
    @State private var isDeleting = false
    @State private var deleteErrorMessage: String?

    var body: some View {
        List {
            Section {
                VStack(spacing: Theme.Spacing.xs) {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 56))
                        .foregroundStyle(Theme.Colors.accent)
                    Text(appState.userEmail.isEmpty ? "Your Account" : appState.userEmail)
                        .font(Theme.Typography.headline)
                        .foregroundStyle(Theme.Colors.textPrimary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Theme.Spacing.md)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
            }

            Section("Subscription") {
                Button("Manage Subscription") {
                    showManageSubscriptions = true
                }
                .foregroundStyle(Theme.Colors.textPrimary)
            }

            Section("Legal") {
                NavigationLink("Privacy Policy") {
                    PrivacyPolicyView()
                }
                NavigationLink("Terms of Use") {
                    TermsOfUseView()
                }
            }
            .foregroundStyle(Theme.Colors.textPrimary)

            Section {
                Button("Sign Out") {
                    appState.signOut()
                }
                .foregroundStyle(Theme.Colors.textPrimary)
            }

            Section {
                Button("Delete Account", role: .destructive) {
                    showDeleteConfirmation = true
                }
                .disabled(isDeleting)
            } footer: {
                if let deleteErrorMessage {
                    Text(deleteErrorMessage)
                        .foregroundStyle(Theme.Colors.scoreLow)
                } else {
                    Text("This permanently deletes your account and all your scans. This can't be undone.")
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(Theme.Colors.background.ignoresSafeArea())
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .manageSubscriptionsSheet(isPresented: $showManageSubscriptions)
        .alert("Delete Account?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                deleteAccount()
            }
        } message: {
            Text("This permanently deletes your account and all your scans. This can't be undone.")
        }
    }

    private func deleteAccount() {
        isDeleting = true
        deleteErrorMessage = nil
        Task {
            do {
                try await appState.deleteAccount()
            } catch {
                isDeleting = false
                deleteErrorMessage = "Couldn't delete your account: \(error.localizedDescription)"
            }
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView()
            .environmentObject(AppState())
    }
}
