// MARK: - PostKit
// DashboardStatusBanner.swift — Scan status banner with progress indicator

import SwiftUI

struct DashboardStatusBanner: View {
    let status: DashboardStatus
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

            if let sub = subhead {
                sub
            }

            if case let .scanning(progress, _, _) = status {
                ProgressBar(value: progress, gradient: true, glow: true)
                    .frame(height: 5)
                    .padding(.top, Spacing.xs)
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
        case .reviewNeeded: Palette.purple
        case .scanning: Palette.accent
        }
    }

    private var headline: String {
        switch status {
        case .idle: "All caught up"
        case .newItems(let n): "\(n) new photo\(n == 1 ? "" : "s")"
        case .reviewNeeded(let n): "\(n) item\(n == 1 ? "" : "s") to review"
        case .scanning: "Scanning your library"
        }
    }

    @ViewBuilder
    private var subhead: (some View)? {
        switch status {
        case .idle:
            staticSubhead("Your library is fully classified")
        case .newItems:
            staticSubhead("Ready to classify")
        case .reviewNeeded:
            staticSubhead("AI wasn't confident — tap to validate")
        case .scanning(_, let processed, let total) where total > 0:
            let remaining = max(total - processed, 0)
            HStack(spacing: 0) {
                Text("\(processed)")
                    .contentTransition(.numericText(countsDown: false))
                Text(" scanned · ")
                Text("\(remaining)")
                    .contentTransition(.numericText(countsDown: true))
                Text(" remaining")
            }
            .font(Typography.footnote)
            .foregroundStyle(Palette.text3)
            .animation(.easeInOut(duration: 0.3), value: processed)
        case .scanning:
            staticSubhead("Starting...")
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
        case .reviewNeeded: "Review"
        case .scanning: "Pause"
        }
    }
}
