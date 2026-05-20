// MARK: - PostKit
// TemplateListView.swift — Template list UI: list of saved templates with create, edit, and delete

import ComposableArchitecture
import SwiftUI

struct TemplateListView: View {
    @Bindable var store: StoreOf<TemplateListFeature>

    var body: some View {
        Group {
            if store.isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if store.templates.isEmpty {
                emptyState
            } else {
                templateList
            }
        }
        .background(Palette.bg)
        .navigationTitle(AppStrings.PostAssembly.title)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    store.send(.newTemplateTapped)
                } label: {
                    Image(systemName: "plus")
                        .fontWeight(.semibold)
                }
            }
        }
        .sheet(item: $store.scope(state: \.builder, action: \.builder)) { builderStore in
            NavigationStack {
                TemplateBuilderView(store: builderStore)
            }
        }
        .sheet(item: $store.scope(state: \.editor, action: \.editor)) { editorStore in
            NavigationStack {
                PostEditorView(store: editorStore)
            }
        }
        .alert($store.scope(state: \.alert, action: \.alert))
        .task { await store.send(.onAppear).finish() }
    }

    private var emptyState: some View {
        VStack(spacing: Spacing.lg) {
            Spacer()

            VStack(spacing: Spacing.md) {
                Image(systemName: "doc.text.image")
                    .font(.system(size: Typography.IconSize.xxl))
                    .foregroundStyle(Palette.text4)

                Text("No templates yet")
                    .font(Typography.title3)
                    .foregroundStyle(Palette.text)

                Text("Create a template to structure your posts.\nEach template defines photo slots with cadrage and pillar requirements.")
                    .font(Typography.footnote)
                    .foregroundStyle(Palette.text3)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Spacing.xl)
            }

            Button {
                store.send(.newTemplateTapped)
            } label: {
                Label("Create Template", systemImage: "plus")
                    .font(Typography.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(Palette.onAccent)
                    .padding(.horizontal, Spacing.xl)
                    .padding(.vertical, Spacing.sm)
                    .background(Palette.accent, in: RoundedRectangle(cornerRadius: Radius.button))
            }

            Spacer()
        }
        .screenPadding()
    }

    private var templateList: some View {
        List {
            ForEach(store.templates) { template in
                Button {
                    store.send(.templateTapped(template))
                } label: {
                    TemplateRowView(template: template)
                }
                .buttonStyle(.plain)
                .swipeActions(edge: .leading) {
                    Button {
                        store.send(.editTemplateTapped(template))
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    .tint(Palette.accent)
                }
            }
            .onDelete { store.send(.deleteTemplate($0)) }
        }
        .listStyle(.insetGrouped)
    }
}

// MARK: - Template Row

private struct TemplateRowView: View {
    let template: TemplateSnapshot

    var body: some View {
        HStack(spacing: Spacing.sm) {
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(template.name)
                    .font(Typography.body)
                    .fontWeight(.medium)
                    .foregroundStyle(Palette.text)

                if !template.about.isEmpty {
                    Text(template.about)
                        .font(Typography.footnote)
                        .foregroundStyle(Palette.text3)
                        .lineLimit(1)
                }

                HStack(spacing: Spacing.xs) {
                    Label(
                        "\(template.slots.count) slot\(template.slots.count == 1 ? "" : "s")",
                        systemImage: "rectangle.3.group"
                    )
                    .font(Typography.caption)
                    .foregroundStyle(Palette.text3)

                    slotMiniPreview
                }
                .padding(.top, 2)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(Typography.caption2)
                .foregroundStyle(Palette.text4)
        }
        .padding(.vertical, Spacing.xxs)
    }

    private var slotMiniPreview: some View {
        HStack(spacing: 3) {
            ForEach(template.slots.prefix(5)) { slot in
                RoundedRectangle(cornerRadius: 3)
                    .fill(Palette.accentTint)
                    .frame(
                        width: 16,
                        height: slot.cadrages == [.portrait] ? 20 : 14
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 3)
                            .strokeBorder(Palette.accent.opacity(0.25), lineWidth: 0.5)
                    )
            }
            if template.slots.count > 5 {
                Text("+\(template.slots.count - 5)")
                    .font(Typography.caption2)
                    .foregroundStyle(Palette.text4)
            }
        }
    }
}
