// MARK: - PostKit
// DashboardStatusBanner.swift — Scan status banner with progress indicator

import SwiftUI

struct DashboardStatusBanner: View {
    @Environment(\.locale) private var locale
    let status: DashboardStatus
    let sortedUpToDate: Date?
    let onPrimary: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            HStack {
                Text(headline)
                    .font(Typography.headline)
                    .foregroundStyle(Palette.text)

                Spacer()

                if let label = primaryActionLabel {
                    Button(label, action: onPrimary)
                        .buttonStyle(.borderedProminent)
                        .tint(tint)
                        .controlSize(.small)
                        .fixedSize()
                }
            }

            subhead

            if case let .scanning(progress, _, _, _) = status {
                ProgressBar(value: progress, gradient: true, glow: true)
                    .frame(height: 5)
                    .padding(.top, Spacing.xs)
                    .animation(.easeInOut(duration: 0.5), value: progress)
            }
        }
        .padding(Layout.Padding.card)
        .cardStyle()
        .accessibilityElement(children: .combine)
    }

    private var tint: Color {
        switch status {
        case .idle: Palette.green
        case .newItems: Palette.yellow
        case .paused: Palette.yellow
        case .scanning: Palette.accent
        }
    }

    private var headline: LocalizedStringKey {
        switch status {
        case .idle: "All caught up"
        case .newItems(let n): n == 1 ? "1 new photo" : "\(n) new photos"
        case .paused(let n): n == 1 ? "1 photo left to sort" : "\(n) photos left to sort"
        case .scanning: "Scanning your library"
        }
    }

    private var sortedDateString: String? {
        guard let date = sortedUpToDate else { return nil }
        return date.formatted(.dateTime.month(.wide).year().locale(locale))
    }

    @ViewBuilder
    private var subhead: some View {
        switch status {
        case .idle:
            if let dateStr = sortedDateString {
                let key: LocalizedStringKey = "Sorted up to \(dateStr)"
                staticSubhead(key)
            } else {
                staticSubhead("Your library is fully classified")
            }
        case .newItems:
            if let dateStr = sortedDateString {
                let key: LocalizedStringKey = "Sorted up to \(dateStr)"
                staticSubhead(key)
            } else {
                staticSubhead("Ready to classify")
            }
        case .paused:
            if let dateStr = sortedDateString {
                let key: LocalizedStringKey = "Sorted up to \(dateStr) · tap to resume"
                staticSubhead(key)
            } else {
                staticSubhead("Scan paused — tap to resume")
            }
        case .scanning(_, let processed, let total, let startedAt) where total > 0:
            let remaining = max(total - processed, 0)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 0) {
                    Text("\(processed)")
                        .contentTransition(.numericText(countsDown: false))
                    Text(" / \(total) photos · ")
                    Text("\(Int(Double(processed) / Double(max(total, 1)) * 100))%")
                        .contentTransition(.numericText(countsDown: false))
                }
                .font(Typography.footnote)
                .foregroundStyle(Palette.text3)
                .animation(.easeInOut(duration: 0.3), value: processed)

                if let eta = Self.estimateETA(processed: processed, remaining: remaining, startedAt: startedAt, locale: locale) {
                    Text(eta)
                        .font(Typography.caption2)
                        .foregroundStyle(Palette.text3)
                }
            }
        case .scanning:
            staticSubhead("Preparing scan...")
        }
    }

    private static func estimateETA(processed: Int, remaining: Int, startedAt: Date?, locale: Locale) -> String? {
        guard let startedAt, processed > 5, remaining > 0 else { return nil }
        let elapsed = Date().timeIntervalSince(startedAt)
        guard elapsed > 0 else { return nil }
        let rate = Double(processed) / elapsed
        guard rate > 0 else { return nil }
        let secondsLeft = Int(Double(remaining) / rate)
        if secondsLeft < 60 {
            let secs = max(secondsLeft, 1)
            return String(localized: "~\(secs) sec remaining", locale: locale)
        } else {
            let minutes = secondsLeft / 60
            return String(localized: "~\(minutes) min remaining", locale: locale)
        }
    }

    private func staticSubhead(_ text: LocalizedStringKey) -> some View {
        Text(text)
            .font(Typography.footnote)
            .foregroundStyle(Palette.text3)
    }

    private var primaryActionLabel: LocalizedStringKey? {
        switch status {
        case .idle: nil
        case .newItems: "Scan now"
        case .paused: "Resume"
        case .scanning: "Pause"
        }
    }
}
