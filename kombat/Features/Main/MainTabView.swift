//
//  MainTabView.swift
//  kombat
//

import SwiftUI

enum MainTab {
    case home
    case video
    case stats
}

struct MainTabView: View {
    @State private var selectedTab: MainTab = .home
    @StateObject private var logRepository = LogRepository()

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                HomeView(onStartScan: { selectedTab = .video })
            }
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            .tag(MainTab.home)

            NavigationStack {
                TrainingLogView()
            }
            .tabItem {
                Label("Log", systemImage: "camera.fill")
            }
            .tag(MainTab.video)

            NavigationStack {
                StatsView()
            }
            .tabItem {
                Label("Stats", systemImage: "chart.bar.fill")
            }
            .tag(MainTab.stats)
        }
        .tint(Theme.Colors.accent)
        .environmentObject(logRepository)
        .task { await logRepository.load() }
    }
}

#Preview {
    MainTabView()
        .environmentObject(AppState())
}
