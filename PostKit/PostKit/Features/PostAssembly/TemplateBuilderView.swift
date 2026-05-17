import ComposableArchitecture
import SwiftUI

struct TemplateBuilderView: View {
    @Bindable var store: StoreOf<TemplateBuilderFeature>

    var body: some View {
        List {
            Section {
                FormField(value: $store.name, placeholder: "Template name")
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())

                TextField("Description (optional)", text: $store.about, axis: .vertical)
                    .font(Typography.body)
                    .lineLimit(2...4)
                    .padding(Layout.Padding.button)
                    .background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.input))
                    .overlay(
                        RoundedRectangle(cornerRadius: Radius.input)
                            .stroke(Palette.border)
                    )
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
            }
            .listRowSeparator(.hidden)

            Section {
                if store.slots.isEmpty {
                    Text("Add slots to define your post structure.")
                        .font(Typography.footnote)
                        .foregroundStyle(Palette.text3)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, Spacing.lg)
                        .listRowBackground(Color.clear)
                } else {
                    ForEach(store.slots) { slot in
                        SlotRowView(slot: slot)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                store.send(.slotTapped(slot))
                            }
                    }
                    .onDelete { store.send(.deleteSlot($0)) }
                    .onMove { store.send(.moveSlot($0, $1)) }
                    .listRowBackground(Palette.surface)
                    .listRowInsets(EdgeInsets(
                        top: Spacing.xs,
                        leading: Layout.Padding.screen.leading,
                        bottom: Spacing.xs,
                        trailing: Layout.Padding.screen.trailing
                    ))
                }

                Button {
                    store.send(.addSlotTapped)
                } label: {
                    Label("Add Slot", systemImage: "plus.circle.fill")
                        .font(Typography.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(Palette.accent)
                }
                .listRowBackground(Color.clear)
            } header: {
                Text("Slots (\(store.slots.count))")
                    .font(Typography.caption)
                    .foregroundStyle(Palette.text3)
            }

            if !store.slots.isEmpty {
                Section {
                    SlotPreviewGrid(slots: store.slots)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets())
                } header: {
                    Text("Preview")
                        .font(Typography.caption)
                        .foregroundStyle(Palette.text3)
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Palette.bg)
        .navigationTitle(store.templateID == nil ? "New Template" : "Edit Template")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") {
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
}

// MARK: - Slot Row

private struct SlotRowView: View {
    let slot: TemplateSlotData

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "line.3.horizontal")
                .font(Typography.caption)
                .foregroundStyle(Palette.text4)

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(slot.name)
                    .font(Typography.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(Palette.text)

                HStack(spacing: Spacing.xxs) {
                    CadrageChip(cadrage: slot.cadrage)

                    ForEach(slot.pillarNames, id: \.self) { name in
                        Text(name)
                            .font(Typography.caption2)
                            .foregroundStyle(Palette.accent)
                            .padding(.horizontal, Spacing.xxs + 2)
                            .padding(.vertical, 2)
                            .background(Palette.accentTint, in: Capsule())
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(Typography.caption2)
                .foregroundStyle(Palette.text4)
        }
    }
}

// MARK: - Cadrage Chip

private struct CadrageChip: View {
    let cadrage: Cadrage

    var body: some View {
        Text(cadrage.displayName)
            .font(Typography.caption2)
            .fontWeight(.medium)
            .foregroundStyle(Palette.text2)
            .padding(.horizontal, Spacing.xxs + 2)
            .padding(.vertical, 2)
            .background(Palette.neutralTint, in: Capsule())
    }
}

// MARK: - Slot Preview Grid

private struct SlotPreviewGrid: View {
    let slots: [TemplateSlotData]

    private var columns: [GridItem] {
        let count = min(slots.count, 4)
        return Array(
            repeating: GridItem(.flexible(), spacing: Layout.Grid.photoGrid),
            count: max(count, 1)
        )
    }

    var body: some View {
        LazyVGrid(columns: columns, spacing: Layout.Grid.photoGrid) {
            ForEach(slots) { slot in
                VStack(spacing: Spacing.xxs) {
                    RoundedRectangle(cornerRadius: Radius.tile)
                        .fill(Palette.surface)
                        .aspectRatio(slot.cadrage == .portrait ? 3/4 : 4/3, contentMode: .fit)
                        .overlay {
                            Text(slot.cadrage.initial)
                                .font(Typography.title2)
                                .fontWeight(.bold)
                                .foregroundStyle(Palette.text4)
                        }
                        .overlay(
                            RoundedRectangle(cornerRadius: Radius.tile)
                                .strokeBorder(Palette.border, lineWidth: Layout.Border.thin)
                        )

                    Text(slot.name)
                        .font(Typography.caption2)
                        .foregroundStyle(Palette.text3)
                        .lineLimit(1)
                }
            }
        }
        .padding(.vertical, Spacing.sm)
    }
}

// MARK: - Slot Editor View

struct SlotEditorView: View {
    @Bindable var store: StoreOf<SlotEditorFeature>

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.lg) {
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text("Name")
                        .font(Typography.caption)
                        .foregroundStyle(Palette.text3)
                    FormField(value: $store.slot.name, placeholder: "Slot name")
                }

                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Cadrage")
                        .font(Typography.caption)
                        .foregroundStyle(Palette.text3)

                    HStack(spacing: Spacing.xs) {
                        ForEach(Cadrage.allCases, id: \.self) { cadrage in
                            Button {
                                store.send(.cadragePicked(cadrage))
                            } label: {
                                Text(cadrage.displayName)
                                    .font(Typography.caption)
                                    .fontWeight(store.slot.cadrage == cadrage ? .semibold : .regular)
                                    .foregroundStyle(
                                        store.slot.cadrage == cadrage ? Palette.onAccent : Palette.text2
                                    )
                                    .padding(.horizontal, Spacing.sm)
                                    .padding(.vertical, Spacing.xxs + 2)
                                    .background(
                                        store.slot.cadrage == cadrage ? Palette.accent : Palette.glassStrong,
                                        in: Capsule()
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Pillars")
                        .font(Typography.caption)
                        .foregroundStyle(Palette.text3)

                    FlowLayout(spacing: Spacing.xs) {
                        ForEach(store.availablePillars) { pillar in
                            let isSelected = store.slot.pillarNames.contains(pillar.name)
                            Button {
                                store.send(.pillarToggled(pillar.name))
                            } label: {
                                Text("\(pillar.emoji) \(pillar.name)")
                                    .font(Typography.caption)
                                    .fontWeight(isSelected ? .semibold : .regular)
                                    .foregroundStyle(isSelected ? Palette.onAccent : Palette.text2)
                                    .padding(.horizontal, Spacing.sm)
                                    .padding(.vertical, Spacing.xxs + 2)
                                    .background(
                                        isSelected ? Palette.accent : Palette.glassStrong,
                                        in: Capsule()
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    if store.availablePillars.isEmpty {
                        Text("No pillars available. Run a scan first.")
                            .font(Typography.caption)
                            .foregroundStyle(Palette.text3)
                    }
                }

                VStack(alignment: .leading, spacing: Spacing.sm) {
                    Text("Tags")
                        .font(Typography.caption)
                        .foregroundStyle(Palette.text3)

                    HStack(spacing: Spacing.xs) {
                        TextField("Add tag…", text: $store.tagInput)
                            .font(Typography.body)
                            .padding(Layout.Padding.button)
                            .background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.input))
                            .overlay(
                                RoundedRectangle(cornerRadius: Radius.input)
                                    .stroke(Palette.border)
                            )
                            .onSubmit { store.send(.addTagTapped) }

                        Button {
                            store.send(.addTagTapped)
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(Typography.title3)
                                .foregroundStyle(Palette.accent)
                        }
                    }

                    if !store.slot.tags.isEmpty {
                        FlowLayout(spacing: Spacing.xxs) {
                            ForEach(store.slot.tags, id: \.self) { tag in
                                HStack(spacing: Spacing.xxs) {
                                    Text(tag)
                                        .font(Typography.caption)
                                    Button {
                                        store.send(.removeTag(tag))
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(Typography.caption2)
                                    }
                                }
                                .foregroundStyle(Palette.text2)
                                .padding(.horizontal, Spacing.xs)
                                .padding(.vertical, Spacing.xxs)
                                .background(Palette.neutralTint, in: Capsule())
                            }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text("Description")
                        .font(Typography.caption)
                        .foregroundStyle(Palette.text3)

                    TextField("What goes in this slot?", text: $store.slot.about, axis: .vertical)
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
            .screenPadding()
        }
        .background(Palette.bg)
        .navigationTitle("Configure Slot")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") {
                    store.send(.saveTapped)
                }
                .fontWeight(.semibold)
            }
        }
    }
}

// MARK: - Flow Layout

private struct FlowLayout: Layout {
    var spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(
                at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                proposal: .unspecified
            )
        }
    }

    private func layout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
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
