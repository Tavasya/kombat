//
//  Theme.swift
//  kombat
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

extension Color {
    /// A color that adapts between light and dark appearance, independent of any asset catalog entry.
    init(light: Color, dark: Color) {
        #if canImport(UIKit)
        self.init(UIColor { traits in
            traits.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
        })
        #else
        self = light
        #endif
    }
}

enum Theme {
    enum Colors {
        static let background = Color(
            light: Color(red: 0.97, green: 0.97, blue: 0.98),
            dark: Color(red: 0.05, green: 0.05, blue: 0.06)
        )
        static let surface = Color(
            light: Color.white,
            dark: Color(red: 0.11, green: 0.11, blue: 0.13)
        )
        static let surfaceElevated = Color(
            light: Color(red: 0.93, green: 0.93, blue: 0.95),
            dark: Color(red: 0.15, green: 0.15, blue: 0.17)
        )

        // Brand accent stays recognizable across both appearances; the dark variant
        // is pulled slightly brighter/warmer so it holds contrast on a near-black surface.
        static let accent = Color(
            light: Color(red: 0.85, green: 0.14, blue: 0.14),
            dark: Color(red: 0.95, green: 0.24, blue: 0.22)
        )
        static let accentSecondary = Color(
            light: Color(red: 0.85, green: 0.52, blue: 0.05),
            dark: Color(red: 0.98, green: 0.62, blue: 0.15)
        )

        static let textPrimary = Color(
            light: Color(red: 0.08, green: 0.08, blue: 0.09),
            dark: Color.white
        )
        static let textSecondary = Color(
            light: Color.black.opacity(0.55),
            dark: Color.white.opacity(0.6)
        )
        static let textTertiary = Color(
            light: Color.black.opacity(0.3),
            dark: Color.white.opacity(0.35)
        )

        static let scoreGood = Color(
            light: Color(red: 0.16, green: 0.62, blue: 0.32),
            dark: Color(red: 0.30, green: 0.82, blue: 0.42)
        )
        static let scoreOK = Color(
            light: Color(red: 0.78, green: 0.55, blue: 0.02),
            dark: Color(red: 0.98, green: 0.72, blue: 0.15)
        )
        static let scoreLow = Color(
            light: Color(red: 0.80, green: 0.20, blue: 0.20),
            dark: Color(red: 0.93, green: 0.30, blue: 0.30)
        )

        static let accentGradient = LinearGradient(
            colors: [accent, accentSecondary],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )

        static let cardBorder = Color(
            light: Color.black.opacity(0.06),
            dark: Color.white.opacity(0.06)
        )

        static let shadow = Color(
            light: Color.black.opacity(0.12),
            dark: Color.black.opacity(0.5)
        )
    }

    enum Typography {
        static func display(_ size: CGFloat) -> Font {
            .system(size: size, weight: .black, design: .rounded)
        }

        static let largeTitle = display(34)
        static let title = display(24)
        static let sectionTitle = Font.system(.title3, design: .rounded).weight(.bold)
        static let headline = Font.system(.headline, design: .rounded).weight(.semibold)
        static let body = Font.system(.body, design: .rounded)
        static let subheadline = Font.system(.subheadline, design: .rounded)
        static let caption = Font.system(.caption, design: .rounded).weight(.medium)
        static let eyebrow = Font.system(.caption, design: .rounded).weight(.bold)
    }

    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }

    enum Radius {
        static let sm: CGFloat = 10
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let pill: CGFloat = 999
    }
}

extension Color {
    static func scoreColor(for score: Int) -> Color {
        switch score {
        case 85...: return Theme.Colors.scoreGood
        case 65..<85: return Theme.Colors.scoreOK
        default: return Theme.Colors.scoreLow
        }
    }
}
