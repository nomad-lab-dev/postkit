// MARK: - PostKit
// CreateHubView.swift — Create tab UI: template carousel, posts list, new template action

import ComposableArchitecture
@preconcurrency import Photos
import SwiftUI

struct CreateHubView: View {
    @Bindable var store: StoreOf<CreateHubFeature>

    var body: some View {
        Group {
            if store.isLoading {
                createHubSkeleton
            } else {
                List {
                    templatesSection
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)

                    postsSection
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .background(Palette.bg)
        .navigationTitle("Create")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Haptics.tap()
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
        .fullScreenCover(item: $store.scope(state: \.slotMachine, action: \.slotMachine)) { machineStore in
            NavigationStack {
                SlotMachineView(store: machineStore)
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

    private var createHubSkeleton: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Spacing.xl) {
                VStack(alignment: .leading, spacing: Spacing.sm) {
                    SkeletonRect(width: 90, height: 14)
                    HStack(spacing: Spacing.sm) {
                        ForEach(0..<3, id: \.self) { _ in
                            SkeletonRect(height: 130, radius: Radius.card)
                                .frame(width: 120)
                        }
                    }
                }

                VStack(alignment: .leading, spacing: Spacing.sm) {
                    SkeletonRect(width: 80, height: 14)
                    ForEach(0..<3, id: \.self) { _ in
                        SkeletonRect(height: 72, radius: Radius.card)
                    }
                }
            }
            .screenPadding()
        }
    }

    // MARK: - Templates

    @ViewBuilder
    private var templatesSection: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            SectionHeader(title: "Templates")
                .padding(.horizontal, Layout.Padding.screen.leading)

            if store.templates.isEmpty {
                Button {
                    store.send(.newTemplateTapped)
                } label: {
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: "plus.circle.dashed")
                            .font(.system(size: Typography.IconSize.lg))
                            .foregroundStyle(Palette.accent)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Create your first template")
                                .font(Typography.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(Palette.text)
                            Text("Define photo slots with cadrage & topic constraints")
                                .font(Typography.caption)
                                .foregroundStyle(Palette.text3)
                        }
                        Spacer()
                    }
                    .padding(Layout.Padding.card)
                    .background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.card))
                    .overlay(
                        RoundedRectangle(cornerRadius: Radius.card)
                            .strokeBorder(Palette.border, lineWidth: Layout.Border.thin)
                    )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, Layout.Padding.screen.leading)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Spacing.sm) {
                        ForEach(store.templates) { template in
                            TemplateCard(template: template, pillars: store.pillars)
                                .onTapGesture {
                                    Haptics.tap()
                                    store.send(.templateSelected(template))
                                }
                                .contextMenu {
                                    Button {
                                        store.send(.editTemplateTapped(template))
                                    } label: {
                                        Label("Edit", systemImage: "pencil")
                                    }
                                    Button(role: .destructive) {
                                        store.send(.deleteTemplateTapped(template))
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                } preview: {
                                    TemplateCard(template: template, pillars: store.pillars)
                                        .padding(Spacing.sm)
                                }
                        }
                    }
                    .padding(.horizontal, Layout.Padding.screen.leading)
                    .padding(.vertical, Spacing.xs)
                }
                .scrollClipDisabled()
            }
        }
    }

    // MARK: - Posts

    @ViewBuilder
    private var postsSection: some View {
        Section {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Spacing.xs) {
                    ForEach(PostFilter.allCases, id: \.self) { filter in
                        Button {
                            Haptics.lightTap()
                            store.send(.filterChanged(filter))
                        } label: {
                            Text(filter.displayName)
                                .font(Typography.subheadline)
                                .fontWeight(store.postFilter == filter ? .semibold : .regular)
                                .foregroundStyle(
                                    store.postFilter == filter ? Palette.onAccent : Palette.text2
                                )
                                .padding(.horizontal, Spacing.sm)
                                .padding(.vertical, Spacing.xxs + 2)
                                .background(
                                    store.postFilter == filter ? Palette.accent : Palette.glassStrong,
                                    in: Capsule()
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .listRowInsets(EdgeInsets(top: 0, leading: Layout.Padding.screen.leading, bottom: Spacing.xs, trailing: Layout.Padding.screen.trailing))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)

            if store.filteredPosts.isEmpty {
                VStack(spacing: Spacing.md) {
                    Image(systemName: "doc.text.image")
                        .font(.system(size: Typography.IconSize.xl))
                        .foregroundStyle(Palette.text4)
                    Text("No posts yet")
                        .font(Typography.subheadline)
                        .foregroundStyle(Palette.text3)
                    if !store.templates.isEmpty {
                        Text("Tap a template above to create your first post")
                            .font(Typography.caption)
                            .foregroundStyle(Palette.text4)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, Spacing.xxl)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            } else {
                ForEach(store.filteredPosts) { post in
                    Button {
                        Haptics.tap()
                        store.send(.postTapped(post))
                    } label: {
                        PostCard(post: post)
                    }
                    .buttonStyle(.plain)
                    .listRowInsets(EdgeInsets(top: Spacing.xxs, leading: Layout.Padding.screen.leading, bottom: Spacing.xxs, trailing: Layout.Padding.screen.trailing))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            store.send(.deletePostTapped(post))
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    .contextMenu {
                        Button(role: .destructive) {
                            store.send(.deletePostTapped(post))
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
        } header: {
            SectionHeader(title: "Your Posts")
                .textCase(nil)
                .padding(.horizontal, Layout.Padding.screen.leading)
        }
        .listSectionSeparator(.hidden)
    }
}

// MARK: - Template Card

private struct TemplateCard: View {
    let template: TemplateSnapshot
    let pillars: [PillarSnapshot]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            slotPreview

            VStack(alignment: .leading, spacing: 2) {
                Text(template.name)
                    .font(Typography.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Palette.text)
                    .lineLimit(1)

                Text("\(template.slots.count) slot\(template.slots.count == 1 ? "" : "s")")
                    .font(Typography.caption)
                    .foregroundStyle(Palette.text3)
            }
            .padding(.horizontal, Spacing.xs)
            .padding(.bottom, Spacing.xs)
        }
        .frame(width: 120)
        .background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.card))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.card)
                .strokeBorder(Palette.border, lineWidth: Layout.Border.thin)
        )
        .contentShape(.contextMenuPreview, RoundedRectangle(cornerRadius: Radius.card))
    }

    private func matchedPillars(for slot: TemplateSlotData) -> [PillarSnapshot] {
        pillars.filter { slot.pillarIDs.contains($0.id) }
    }

    private var slotPreview: some View {
        let cols = min(template.slots.count, 2)
        let gridItems = Array(repeating: GridItem(.flexible(), spacing: 2), count: max(cols, 1))
        return LazyVGrid(columns: gridItems, spacing: 2) {
            ForEach(template.slots.prefix(4)) { slot in
                let matched = matchedPillars(for: slot)
                Color.clear
                    .aspectRatio(1, contentMode: .fill)
                    .background(Palette.accentTint)
                    .overlay {
                        if matched.isEmpty {
                            if let first = slot.cadrages.first {
                                CadrageTag(cadrage: first)
                            }
                        } else {
                            HStack(spacing: -4) {
                                ForEach(matched.prefix(3)) { pillar in
                                    Text(pillar.emoji)
                                        .font(.system(size: 12))
                                        .frame(width: 20, height: 20)
                                        .background(Palette.surface, in: Circle())
                                        .overlay(Circle().strokeBorder(Palette.border, lineWidth: 0.5))
                                }
                            }
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
        }
        .padding(Spacing.xs)
    }
}

// MARK: - Post Card

private struct PostCard: View {
    let post: GeneratedPostSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            photoStrip

            if !post.caption.isEmpty {
                Text(post.caption)
                    .font(Typography.footnote)
                    .foregroundStyle(Palette.text2)
                    .lineLimit(2)
                    .padding(.horizontal, Spacing.xs)
            }

            HStack(spacing: Spacing.xs) {
                Text("\(post.photoIDs.count) photo\(post.photoIDs.count == 1 ? "" : "s")")
                    .font(Typography.caption)
                    .foregroundStyle(Palette.text3)

                Text("·")
                    .foregroundStyle(Palette.text4)

                Text(post.createdAt, style: .date)
                    .font(Typography.caption)
                    .foregroundStyle(Palette.text3)

                Spacer()

                StatusBadge(status: post.status)
            }
            .padding(.horizontal, Spacing.xs)
        }
        .padding(.vertical, Spacing.xs)
        .background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.card))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.card)
                .strokeBorder(Palette.border, lineWidth: Layout.Border.thin)
        )
    }

    private var photoStrip: some View {
        let ids = Array(post.photoIDs.prefix(5))
        let overflow = post.photoIDs.count > 5 ? post.photoIDs.count - 5 : 0
        return HStack(spacing: 2) {
            ForEach(Array(ids.enumerated()), id: \.element) { index, assetID in
                PostStripThumbnail(
                    assetIdentifier: assetID,
                    extraCount: index == ids.count - 1 ? overflow : 0
                )
            }
        }
        .frame(height: 80)
        .clipShape(RoundedRectangle(cornerRadius: Radius.tile))
        .padding(.horizontal, Spacing.xs)
    }
}

// MARK: - Status Badge

private struct StatusBadge: View {
    let status: PostStatus

    private var color: Color {
        switch status {
        case .draft: Palette.text3
        case .ready: Palette.green
        case .published: Palette.accent
        }
    }

    var body: some View {
        Text(status.displayName)
            .font(Typography.caption2)
            .fontWeight(.medium)
            .foregroundStyle(color)
            .padding(.horizontal, Spacing.xs)
            .padding(.vertical, 2)
            .background(color.opacity(0.1), in: Capsule())
    }
}

// MARK: - Post Strip Thumbnail

private struct PostStripThumbnail: View {
    let assetIdentifier: String
    var extraCount: Int = 0
    @State private var image: UIImage?

    var body: some View {
        Color.clear
            .frame(maxWidth: .infinity)
            .overlay {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    Palette.placeholder
                }
            }
            .clipped()
            .overlay {
                if extraCount > 0 {
                    Color.black.opacity(0.45)
                    Text("+\(extraCount)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
            .task(id: assetIdentifier) {
                let fetchResult = PHAsset.fetchAssets(
                    withLocalIdentifiers: [assetIdentifier], options: nil
                )
                guard let asset = fetchResult.firstObject else { return }
                let scale = UIScreen.main.scale
                let side = ceil(80 * scale)
                let options = PHImageRequestOptions()
                options.deliveryMode = .opportunistic
                options.isNetworkAccessAllowed = false
                PHImageManager.default().requestImage(
                    for: asset, targetSize: CGSize(width: side, height: side),
                    contentMode: .aspectFill, options: options
                ) { result, _ in
                    guard let result else { return }
                    Task { @MainActor in self.image = result }
                }
            }
    }
}
