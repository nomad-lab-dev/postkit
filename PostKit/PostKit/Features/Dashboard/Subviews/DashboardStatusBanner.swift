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
                Text(sub)
                    .font(Typography.footnote)
                    .foregroundStyle(Palette.text3)
            }

            if case let .scanning(progress, _, _) = status {
                ProgressBar(value: progress, tint: Palette.accent)
                    .frame(height: 4)
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

    private var subhead: String? {
        switch status {
        case .idle:
            return "Your library is fully classified"
        case .newItems:
            return "Ready to classify"
        case .reviewNeeded:
            return "AI wasn't confident — tap to validate"
        case .scanning(_, let processed, let total) where total > 0:
            let remaining = max(total - processed, 0)
            let pct = Int((Double(processed) / Double(total)) * 100)
            return "\(processed) scanned · \(remaining) remaining (\(pct)%)"
        case .scanning:
            return "Starting..."
        }
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
