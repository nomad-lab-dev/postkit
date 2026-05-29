// MARK: - PostKit
// DashboardHero.swift — Top-of-dashboard greeting + total-photos hero number.
// Also hosts the .statusStrip(_:) modifier used to render the wireframe's
// state-coded left strip on the status banner.

import SwiftUI

struct DashboardHero: View {
    let totalSorted: Int
    let pillarCount: Int

    private var greeting: String {
        switch Calendar.current.component(.hour, from: Date()) {
        case 5..<12:  return "Good morning"
        case 12..<18: return "Good afternoon"
        default:      return "Good evening"
        }
    }

    private var noun: String {
        totalSorted == 1 ? "photo ready" : "photos ready"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            Text(greeting)
                .eyebrow()

            HStack(alignment: .firstTextBaseline, spacing: Spacing.xs) {
                Text("\(totalSorted)")
                    .font(.system(size: 52, weight: .heavy, design: .rounded))
                    .foregroundStyle(Palette.text)
                    .contentTransition(.numericText(countsDown: false))
                    .monospacedDigit()
                    .animation(.snappy(duration: 0.4), value: totalSorted)

                Text(noun)
                    .font(Typography.title3)
                    .foregroundStyle(Palette.text2)
                    .padding(.bottom, 6)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(totalSorted) photos sorted across \(pillarCount) pillars")
    }
}

// MARK: - Status strip modifier

extension View {
    /// Inset color strip pinned to the leading edge — used to make banner
    /// state recognisable pre-attentively (matches wireframe spec).
    func statusStrip(_ color: Color) -> some View {
        overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(color)
                .frame(width: 4)
                .padding(.vertical, Spacing.md)
                .padding(.leading, Spacing.xxs)
                .allowsHitTesting(false)
        }
    }
}

extension DashboardStatus {
    var stripColor: Color {
        switch self {
        case .idle:         return Palette.green
        case .newItems:     return Palette.yellow
        case .paused:       return Palette.yellow
        case .scanning:     return Palette.accent
        }
    }
}

// MARK: - Previews

#Preview("Hero — fresh user") {
    DashboardHero(totalSorted: 0, pillarCount: 0)
        .padding()
        .background(Palette.bg)
}

#Preview("Hero — active user") {
    DashboardHero(totalSorted: 1_247, pillarCount: 4)
        .padding()
        .background(Palette.bg)
}
