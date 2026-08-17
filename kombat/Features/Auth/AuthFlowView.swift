//
//  AuthFlowView.swift
//  kombat
//

import SwiftUI

struct AuthFlowView: View {
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            PhoneEntryView(path: $path)
                .navigationDestination(for: String.self) { phone in
                    VerificationCodeView(phone: phone)
                }
        }
    }
}

#Preview {
    AuthFlowView()
        .environmentObject(AppState())
}
