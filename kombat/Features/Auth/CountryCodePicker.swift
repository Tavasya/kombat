//
//  CountryCodePicker.swift
//  kombat
//

import SwiftUI

struct CountryCodePicker: View {
    @Binding var selectedCountry: Country
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""

    private var filteredCountries: [Country] {
        guard !searchText.isEmpty else { return Country.all }
        return Country.all.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) || $0.dialCode.contains(searchText)
        }
    }

    var body: some View {
        NavigationStack {
            List(filteredCountries) { country in
                Button {
                    selectedCountry = country
                    dismiss()
                } label: {
                    HStack {
                        Text(country.flag)
                        Text(country.name)
                            .foregroundStyle(Theme.Colors.textPrimary)
                        Spacer()
                        Text(country.dialCode)
                            .foregroundStyle(Theme.Colors.textSecondary)
                    }
                }
                .listRowBackground(Theme.Colors.surface)
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Theme.Colors.background.ignoresSafeArea())
            .searchable(text: $searchText, prompt: "Search countries")
            .navigationTitle("Country")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
