// MARK: - PostKit
// DashboardStatusBanner.swift — Scan status banner with progress indicator

import SwiftUI

struct DashboardStatusBanner: View {
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

    private var headline: String {
        switch status {
        case .idle: "All caught up"
        case .newItems(let n): "\(n) new photo\(n == 1 ? "" : "s")"
        case .paused(let n): "\(n) photo\(n == 1 ? "" : "s") left to sort"
        case .scanning: "Scanning your library"
        }
    }

    private var sortedDateLine: String? {
        guard let date = sortedUpToDate else { return nil }
        return "Sorted up to \(date.formatted(.dateTime.month(.wide).year()))"
    }

    @ViewBuilder
    private var subhead: some View {
        switch status {
        case .idle:
            if let line = sortedDateLine {
                staticSubhead(line)
            } else {
                staticSubhead("Your library is fully classified")
            }
        case .newItems:
            if let line = sortedDateLine {
                staticSubhead(line)
            } else {
                staticSubhead("Ready to classify")
            }
        case .paused:
            if let line = sortedDateLine {
                staticSubhead("\(line) · tap to resume")
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

                if let eta = Self.estimateETA(processed: processed, remaining: remaining, startedAt: startedAt) {
                    Text(eta)
                        .font(Typography.caption2)
                        .foregroundStyle(Palette.text3)
                }
            }
        case .scanning:
            staticSubhead("Preparing scan...")
        }
    }

    private static func estimateETA(processed: Int, remaining: Int, startedAt: Date?) -> String? {
        guard let startedAt, processed > 5, remaining > 0 else { return nil }
        let elapsed = Date().timeIntervalSince(startedAt)
        guard elapsed > 0 else { return nil }
        let rate = Double(processed) / elapsed
        guard rate > 0 else { return nil }
        let secondsLeft = Int(Double(remaining) / rate)
        if secondsLeft < 60 {
            return "~\(max(secondsLeft, 1))s remaining"
        } else {
            let minutes = secondsLeft / 60
            return "~\(minutes) min remaining"
        }
    }

    private func staticSubhead(_ text: String) -> some View {
        Text(text)
            .font(Typography.footnote)
            .foregroundStyle(Palette.text3)
    }

    private var primaryActionLabel: String? {
        switch status {
        case .idle: nil
        case .newItems: "Scan now"
        case .paused: "Resume"
        case .scanning: "Pause"
        }
    }
}
