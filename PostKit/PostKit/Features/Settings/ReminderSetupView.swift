// MARK: - PostKit
// ReminderSetupView.swift — Posting cadence reminder setup UI: day picker, time, confirm/skip

import ComposableArchitecture
import SwiftUI

struct ReminderSetupView: View {
    @Bindable var store: StoreOf<ReminderSetupFeature>

    private let days: [(id: Int, label: String, short: String)] = [
        (1, "Sunday", "S"),
        (2, "Monday", "M"),
        (3, "Tuesday", "T"),
        (4, "Wednesday", "W"),
        (5, "Thursday", "T"),
        (6, "Friday", "F"),
        (7, "Saturday", "S"),
    ]

    var body: some View {
        VStack(spacing: Spacing.lg) {
            VStack(spacing: Spacing.sm) {
                Image(systemName: "bell.badge")
                    .font(.system(size: 44, weight: .light))
                    .foregroundStyle(Palette.accent)

                Text("Stay consistent")
                    .font(Typography.title2)
                    .fontWeight(.bold)

                Text("Pick the days you want to post.\nPostKit will remind you when it's time.")
                    .font(Typography.subheadline)
                    .foregroundStyle(Palette.text3)
                    .multilineTextAlignment(.center)
            }
            .padding(.top, Spacing.xl)

            HStack(spacing: Spacing.xs) {
                ForEach(days, id: \.id) { day in
                    let isSelected = store.selectedDays.contains(day.id)
                    Button {
                        Haptics.selection()
                        store.send(.dayToggled(day.id))
                    } label: {
                        Text(day.short)
                            .font(Typography.subheadline)
                            .fontWeight(isSelected ? .bold : .regular)
                            .foregroundStyle(isSelected ? Palette.onAccent : Palette.text3)
                            .frame(width: 40, height: 40)
                            .background(
                                isSelected ? Palette.accent : Palette.glassStrong,
                                in: Circle()
                            )
                            .overlay(
                                Circle()
                                    .strokeBorder(
                                        isSelected ? Color.clear : Palette.border,
                                        lineWidth: Layout.Border.thin
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                    .animation(.easeInOut(duration: 0.15), value: isSelected)
                }
            }

            HStack(spacing: Spacing.sm) {
                Image(systemName: "clock")
                    .foregroundStyle(Palette.text3)
                DatePicker(
                    "Remind at",
                    selection: $store.reminderTime,
                    displayedComponents: .hourAndMinute
                )
                .labelsHidden()
            }
            .padding(Spacing.sm)
            .background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.input))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.input)
                    .strokeBorder(Palette.border, lineWidth: Layout.Border.thin)
            )

            Spacer()

            VStack(spacing: Spacing.sm) {
                Button {
                    Haptics.success()
                    store.send(.confirmTapped)
                } label: {
                    if store.isScheduling {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Spacing.sm)
                    } else {
                        Text("Set reminders")
                            .font(Typography.body)
                            .fontWeight(.semibold)
                            .foregroundStyle(Palette.onAccent)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Spacing.sm)
                            .background(Palette.accent, in: RoundedRectangle(cornerRadius: Radius.button))
                    }
                }
                .disabled(store.selectedDays.isEmpty || store.isScheduling)

                Button {
                    store.send(.skipTapped)
                } label: {
                    Text("Not now")
                        .font(Typography.subheadline)
                        .foregroundStyle(Palette.text3)
                }
                .buttonStyle(.plain)
            }
            .padding(.bottom, Spacing.xxl)
        }
        .padding(.horizontal, Spacing.xl)
        .background(Palette.bg)
    }
}
