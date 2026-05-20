import ComposableArchitecture
import SwiftUI

struct TemplateBuilderView: View {
    @Bindable var store: StoreOf<TemplateBuilderFeature>

    private let gridColumns = Array(
        repeating: GridItem(.flexible(), spacing: Spacing.sm),
        count: 2
    )

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                FormField(value: $store.name, placeholder: "Template name")
                locationSection
                slotsSection
                scheduleSection
                promptSection
            }
            .screenPadding()
        }
        .background(Palette.bg)
        .navigationTitle(store.templateID == nil ? "New Template" : "Edit Template")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") {
                    Haptics.success()
                    store.send(.saveTapped)
                }
                .fontWeight(.semibold)
                .disabled(!store.canSave)
            }
        }
        .sheet(item: $store.scope(state: \.slotEditor, action: \.slotEditor)) { editorStore in
            NavigationStack {
                SlotEditorView(store: editorStore)
            }
            .presentationDetents([.medium, .large])
        }
        .alert($store.scope(state: \.alert, action: \.alert))
        .task { await store.send(.onAppear).finish() }
    }

    @ViewBuilder
    private var locationSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Location")
                .font(Typography.caption)
                .foregroundStyle(Palette.text3)

            if !store.selectedLocations.isEmpty {
                FlowLayout(spacing: Spacing.xs) {
                    ForEach(store.selectedLocations, id: \.self) { location in
                        Button {
                            Haptics.lightTap()
                            store.send(.locationRemoved(location))
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "mappin")
                                    .font(.system(size: 10))
                                Text(location)
                                    .font(Typography.subheadline)
                                    .fontWeight(.semibold)
                                Image(systemName: "xmark")
                                    .font(.system(size: 9, weight: .bold))
                            }
                            .foregroundStyle(Palette.onAccent)
                            .padding(.horizontal, Spacing.sm)
                            .padding(.vertical, Spacing.xs)
                            .background(Palette.accent, in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: Spacing.xs) {
                    TextField("Add a location…", text: $store.locationQuery)
                        .font(Typography.body)
                        .onSubmit { commitLocation() }
                        .submitLabel(.done)

                    Button {
                        commitLocation()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 22))
                            .foregroundStyle(
                                store.locationQuery.trimmingCharacters(in: .whitespaces).isEmpty
                                    ? Palette.text4 : Palette.accent
                            )
                    }
                    .disabled(store.locationQuery.trimmingCharacters(in: .whitespaces).isEmpty)
                    .buttonStyle(.plain)
                }
                .padding(Layout.Padding.button)
                .background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.input))
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.input)
                        .stroke(Palette.border)
                )

                if !store.suggestedLocations.isEmpty {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(store.suggestedLocations.prefix(6).enumerated()), id: \.element) { index, location in
                            let isFromGallery = store.availableLocations.contains(location)
                            Button {
                                Haptics.lightTap()
                                store.send(.locationSelected(location))
                            } label: {
                                HStack(spacing: Spacing.xs) {
                                    Image(systemName: isFromGallery ? "photo.circle.fill" : "mappin.circle.fill")
                                        .font(.system(size: 14))
                                        .foregroundStyle(isFromGallery ? Palette.accent : Palette.text3)
                                    Text(location)
                                        .font(Typography.subheadline)
                                        .foregroundStyle(Palette.text)
                                    Spacer()
                                    if isFromGallery {
                                        Text("gallery")
                                            .font(Typography.caption2)
                                            .foregroundStyle(Palette.accent)
                                    }
                                }
                                .padding(.horizontal, Spacing.sm)
                                .padding(.vertical, Spacing.sm)
                            }
                            .buttonStyle(.plain)

                            if index < store.suggestedLocations.prefix(6).count - 1 {
                                Divider().padding(.leading, Spacing.xl)
                            }
                        }
                    }
                    .background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.card))
                    .overlay(
                        RoundedRectangle(cornerRadius: Radius.card)
                            .strokeBorder(Palette.border, lineWidth: Layout.Border.thin)
                    )
                }
            }

            if store.selectedLocations.isEmpty {
                Text("No location selected — any location will match")
                    .font(Typography.caption)
                    .foregroundStyle(Palette.text3)
                    .italic()
            }
        }
    }

    private func commitLocation() {
        let trimmed = store.locationQuery.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        Haptics.lightTap()
        if let match = store.suggestedLocations.first {
            store.send(.locationSelected(match))
        } else {
            store.send(.locationSelected(trimmed))
        }
    }

    @ViewBuilder
    private var promptSection: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            Text("Prompt (optional)")
                .font(Typography.caption)
                .foregroundStyle(Palette.text3)
            TextField("Guide the AI caption style…", text: $store.about, axis: .vertical)
                .font(Typography.body)
                .lineLimit(2...4)
                .padding(Layout.Padding.button)
                .background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.input))
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.input)
                        .stroke(Palette.border)
                )
        }
    }

    @ViewBuilder
    private var slotsSection: some View {
        SectionHeader(title: "Slots (\(store.slots.count))")

        LazyVGrid(columns: gridColumns, spacing: Spacing.sm) {
            ForEach(store.slots) { slot in
                SlotGridCell(
                    slot: slot,
                    pillars: store.availablePillars,
                    onTap: { store.send(.slotTapped(slot)) },
                    onDelete: { store.send(.deleteSlotByID(slot.id)) }
                )
            }

            Button {
                Haptics.tap()
                store.send(.addSlotTapped)
            } label: {
                Palette.surface
                    .aspectRatio(1, contentMode: .fit)
                    .overlay {
                        VStack(spacing: Spacing.xs) {
                            Image(systemName: "plus")
                                .font(.system(size: 24, weight: .semibold))
                                .foregroundStyle(Palette.accent)
                            Text("Add Slot")
                                .font(Typography.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(Palette.text2)
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: Radius.card))
                    .overlay(
                        RoundedRectangle(cornerRadius: Radius.card)
                            .strokeBorder(Palette.border, style: StrokeStyle(lineWidth: Layout.Border.thin, dash: [6]))
                    )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Schedule

    @ViewBuilder
    private var scheduleSection: some View {
        SectionHeader(title: "Schedule")

        VStack(alignment: .leading, spacing: Spacing.sm) {
            HStack(spacing: 0) {
                ForEach(Weekday.allCases) { day in
                    let isSelected = store.schedule.weekdays.contains(day)
                    Button {
                        Haptics.lightTap()
                        store.send(.weekdayToggled(day))
                    } label: {
                        Text(day.initial)
                            .font(Typography.caption)
                            .fontWeight(isSelected ? .bold : .regular)
                            .foregroundStyle(isSelected ? Palette.onAccent : Palette.text3)
                            .frame(width: 36, height: 36)
                            .background(
                                isSelected ? Palette.accent : Palette.glassStrong,
                                in: Circle()
                            )
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                }
            }

            if !store.schedule.weekdays.isEmpty {
                let sorted = store.schedule.weekdays.sorted()
                let names = sorted.map(\.shortName).joined(separator: ", ")
                HStack(spacing: Spacing.sm) {
                    Image(systemName: "bell.badge")
                        .font(Typography.subheadline)
                        .foregroundStyle(store.schedule.reminderEnabled ? Palette.accent : Palette.text4)

                    Text("Remind me \(names)")
                        .font(Typography.caption)
                        .foregroundStyle(Palette.text2)

                    Spacer()

                    Toggle("", isOn: Binding(
                        get: { store.schedule.reminderEnabled },
                        set: { _ in store.send(.reminderToggled) }
                    ))
                    .labelsHidden()
                    .tint(Palette.accent)
                }
                .padding(Spacing.sm)
                .background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.card))
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.card)
                        .strokeBorder(Palette.border, lineWidth: Layout.Border.thin)
                )
            } else {
                Text("No schedule — select days to get posting reminders")
                    .font(Typography.caption)
                    .foregroundStyle(Palette.text3)
                    .italic()
            }
        }
    }
}

// MARK: - Slot Grid Cell

private struct SlotGridCell: View {
    let slot: TemplateSlotData
    let pillars: [PillarSnapshot]
    let onTap: () -> Void
    let onDelete: () -> Void

    private var matchedPillars: [PillarSnapshot] {
        pillars.filter { slot.pillarIDs.contains($0.id) }
    }

    var body: some View {
        Button(action: { Haptics.tap(); onTap() }) {
            ZStack {
                Palette.accentTint

                if matchedPillars.isEmpty {
                    if slot.cadrages.isEmpty {
                        Text("?")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundStyle(Palette.accent.opacity(0.4))
                    } else {
                        HStack(spacing: Spacing.xxs) {
                            ForEach(slot.cadrages.prefix(3), id: \.self) { c in
                                CadrageTag(cadrage: c)
                            }
                        }
                    }
                } else {
                    pillarEmojiStack
                }
            }
            .aspectRatio(1, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: Radius.card))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.card)
                    .strokeBorder(Palette.border, lineWidth: Layout.Border.thin)
            )
            .overlay(alignment: .topTrailing) {
                Button {
                    Haptics.lightTap()
                    onDelete()
                } label: {
                    Image(systemName: "trash.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(Palette.red)
                        .background(.white, in: Circle())
                }
                .offset(x: 6, y: -6)
            }
        }
        .buttonStyle(.plain)
    }

    private var pillarEmojiStack: some View {
        let emojis = matchedPillars.prefix(3)
        return ZStack {
            ForEach(Array(emojis.enumerated()), id: \.element.id) { index, pillar in
                Text(pillar.emoji)
                    .font(.system(size: 22))
                    .frame(width: 36, height: 36)
                    .background(Palette.surface, in: Circle())
                    .overlay(Circle().strokeBorder(Palette.border, lineWidth: 1))
                    .offset(x: CGFloat(index - (emojis.count - 1)) * 12)
            }
        }
    }
}

// MARK: - Slot Editor View

struct SlotEditorView: View {
    @Bindable var store: StoreOf<SlotEditorFeature>

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Pillar")
                        .font(Typography.caption)
                        .foregroundStyle(Palette.text3)

                    FlowLayout(spacing: Spacing.xs) {
                        ForEach(store.availablePillars) { pillar in
                            let isSelected = store.slot.pillarIDs.contains(pillar.id)
                            Button {
                                Haptics.selection()
                                store.send(.pillarToggled(pillar.id))
                            } label: {
                                HStack(spacing: 4) {
                                    Text(pillar.emoji)
                                        .font(.system(size: 14))
                                    Text(pillar.name)
                                        .font(Typography.subheadline)
                                        .fontWeight(isSelected ? .semibold : .regular)
                                    if isSelected {
                                        Image(systemName: "xmark")
                                            .font(.system(size: 9, weight: .bold))
                                    }
                                }
                                .foregroundStyle(isSelected ? Palette.onAccent : Palette.text2)
                                .padding(.horizontal, Spacing.sm)
                                .padding(.vertical, Spacing.xs)
                                .background(
                                    isSelected ? Palette.accent : Palette.glassStrong,
                                    in: Capsule()
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    if store.slot.pillarIDs.isEmpty {
                        Text("No pillar selected — any pillar will match")
                            .font(Typography.caption)
                            .foregroundStyle(Palette.text3)
                            .italic()
                    }
                }

                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Cadrage")
                        .font(Typography.caption)
                        .foregroundStyle(Palette.text3)

                    FlowLayout(spacing: Spacing.xs) {
                        ForEach(Cadrage.detectableCases, id: \.self) { cadrage in
                            let isSelected = store.slot.cadrages.contains(cadrage)
                            Button {
                                Haptics.lightTap()
                                store.send(.cadrageToggled(cadrage))
                            } label: {
                                HStack(spacing: 4) {
                                    Text(cadrage.displayName)
                                        .font(Typography.subheadline)
                                        .fontWeight(isSelected ? .semibold : .regular)
                                    if isSelected {
                                        Image(systemName: "xmark")
                                            .font(.system(size: 9, weight: .bold))
                                    }
                                }
                                .foregroundStyle(isSelected ? Palette.onAccent : Palette.text2)
                                .padding(.horizontal, Spacing.sm)
                                .padding(.vertical, Spacing.xs)
                                .background(
                                    isSelected ? Palette.accent : Palette.glassStrong,
                                    in: Capsule()
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    if store.slot.cadrages.isEmpty {
                        Text("No cadrage selected — any cadrage will match")
                            .font(Typography.caption)
                            .foregroundStyle(Palette.text3)
                            .italic()
                    }
                }

            }
            .screenPadding()
        }
        .background(Palette.bg)
        .navigationTitle(store.isNew ? "New Slot" : "Edit Slot")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(store.isNew ? "Create" : "Done") {
                    Haptics.success()
                    store.send(.saveTapped)
                }
                .fontWeight(.semibold)
            }
        }
    }
}

// MARK: - Flow Layout

private struct FlowLayout: SwiftUI.Layout {
    var spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: SwiftUI.Layout.Subviews, cache: inout ()) -> CGSize {
        let result = layout(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: SwiftUI.Layout.Subviews, cache: inout ()) {
        let result = layout(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: .unspecified
            )
        }
    }

    private func layout(proposal: ProposedViewSize, subviews: SwiftUI.Layout.Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        return (CGSize(width: maxWidth, height: y + rowHeight), positions)
    }
}
