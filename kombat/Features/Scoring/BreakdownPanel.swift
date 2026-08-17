//
//  BreakdownPanel.swift
//  kombat
//

import SwiftUI

/// The scoring evidence under the player: overall score, per-rule bars, and
/// tappable findings that seek the video to the moment form broke down.
struct BreakdownPanel: View {
    let score: Int
    let breakdown: ScanBreakdown
    let onSeek: (Double) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                HStack {
                    Text(breakdown.repCount > 0 ? "\(breakdown.repCount) punches analyzed" : "Form Analysis")
                        .font(Theme.Typography.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.Colors.textPrimary)
                    Spacer()
                    ScoreBadge(score: score)
                }

                if let note = breakdown.note {
                    Text(note)
                        .font(Theme.Typography.caption)
                        .foregroundStyle(Theme.Colors.textSecondary)
                }

                if let techniques = breakdown.techniques, !techniques.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: Theme.Spacing.sm) {
                            ForEach(techniques) { entry in
                                VStack(spacing: 2) {
                                    Text("\(entry.count)× \(entry.technique)")
                                        .font(Theme.Typography.caption.weight(.semibold))
                                        .foregroundStyle(Theme.Colors.textPrimary)
                                    Text("avg \(entry.averageScore)")
                                        .font(Theme.Typography.caption)
                                        .foregroundStyle(Theme.Colors.textSecondary)
                                }
                                .padding(.horizontal, Theme.Spacing.sm)
                                .padding(.vertical, 6)
                                .background(Theme.Colors.surface, in: Capsule())
                            }
                        }
                    }
                }

                ForEach(breakdown.ruleScores) { rule in
                    HStack(spacing: Theme.Spacing.sm) {
                        Text(rule.rule)
                            .font(Theme.Typography.caption)
                            .foregroundStyle(Theme.Colors.textSecondary)
                            .frame(width: 80, alignment: .leading)
                        GeometryReader { proxy in
                            ZStack(alignment: .leading) {
                                Capsule().fill(Theme.Colors.surface)
                                Capsule()
                                    .fill(Theme.Colors.accent)
                                    .frame(width: proxy.size.width * CGFloat(rule.score) / 100)
                            }
                        }
                        .frame(height: 6)
                        Text("\(rule.score)")
                            .font(Theme.Typography.caption.monospacedDigit())
                            .foregroundStyle(Theme.Colors.textPrimary)
                            .frame(width: 30, alignment: .trailing)
                    }
                }

                if !breakdown.findings.isEmpty {
                    Text("Moments to review")
                        .font(Theme.Typography.caption.weight(.semibold))
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .padding(.top, Theme.Spacing.xs)

                    ForEach(breakdown.findings) { finding in
                        Button {
                            onSeek(finding.time)
                        } label: {
                            HStack(spacing: Theme.Spacing.sm) {
                                Image(systemName: "play.circle")
                                    .foregroundStyle(Theme.Colors.accent)
                                Text(finding.message)
                                    .font(Theme.Typography.caption)
                                    .foregroundStyle(Theme.Colors.textPrimary)
                                Spacer()
                                Text(timeText(finding.time))
                                    .font(Theme.Typography.caption.monospacedDigit())
                                    .foregroundStyle(Theme.Colors.textSecondary)
                            }
                            .padding(Theme.Spacing.sm)
                            .background(Theme.Colors.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.sm, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(Theme.Spacing.md)
        }
        .background(Theme.Colors.background)
    }

    private func timeText(_ seconds: Double) -> String {
        let total = Int(seconds)
        return String(format: "%d:%02d", total / 60, total % 60)
    }
}
