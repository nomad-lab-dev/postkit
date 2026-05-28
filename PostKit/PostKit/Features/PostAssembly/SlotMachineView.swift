// MARK: - PostKit
// SlotMachineView.swift — Slot machine UI: loading, shuffling animation, and revealed slots

import ComposableArchitecture
@preconcurrency import Photos
import SwiftUI

struct SlotMachineView: View {
    let store: StoreOf<SlotMachineFeature>

    var body: some View {
        VStack(spacing: 0) {
            switch store.phase {
            case .loading:
                Spacer()
                loadingState
                Spacer()
            case .shuffling:
                Spacer()
                shufflingState
                Spacer()
            case .revealed:
                revealedState
            case .noPhotos:
                Spacer()
                noPhotosState
                Spacer()
            }

            if store.phase == .revealed {
                Divider()
                actionButtons
            }
        }
        .background(Palette.bg)
        .navigationTitle(store.template.name)
        .navigationBarTitleDisplayMode(.inline)
        .task { await store.send(.onAppear).finish() }
    }

    // MARK: - Loading

    private var loadingState: some View {
        VStack(spacing: Spacing.md) {
            ProgressView()
            Text("Finding photos...")
                .font(Typography.subheadline)
                .foregroundStyle(Palette.text3)
        }
    }

    // MARK: - Shuffling

    private var shufflingState: some View {
        VStack(spacing: Spacing.lg) {
            Text("Picking from your gallery")
                .font(Typography.title3)
                .fontWeight(.bold)
                .foregroundStyle(Palette.text)

            slotList(blurred: true, interactive: false)
                .frame(maxHeight: 300)

            ProgressView()
                .tint(Palette.accent)
        }
        .screenPadding()
    }

    // MARK: - Revealed

    private var revealedState: some View {
        VStack(spacing: 0) {
            VStack(spacing: Spacing.xxs) {
                Text("Your post is ready")
                    .font(Typography.title3)
                    .fontWeight(.bold)
                    .foregroundStyle(Palette.text)

                Text("\(store.template.name) — \(store.filledSlots.count) slides")
                    .font(Typography.subheadline)
                    .foregroundStyle(Palette.text3)
            }
            .padding(.top, Spacing.md)
            .padding(.bottom, Spacing.sm)

            slotList(blurred: false, interactive: true)
        }
    }

    // MARK: - No Photos

    private var noPhotosState: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: Typography.IconSize.xxl))
                .foregroundStyle(Palette.text4)

            Text("Not enough classified photos")
                .font(Typography.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(Palette.text2)

            Text("Classify more photos from the Dashboard to fill these slots.")
                .font(Typography.caption)
                .foregroundStyle(Palette.text3)
                .multilineTextAlignment(.center)
        }
        .screenPadding()
    }

    // MARK: - Slot List

    private func slotList(blurred: Bool, interactive: Bool) -> some View {
        ScrollView {
            LazyVStack(spacing: Spacing.md) {
                ForEach(Array(store.filledSlots.enumerated()), id: \.element.id) { index, slot in
                    SlotMachineCell(
                        slot: slot,
                        index: index,
                        pillars: store.pillars,
                        blurred: blurred,
                        interactive: interactive,
                        isReshuffling: store.reshufflingSlotID == slot.id,
                        onShuffle: { store.send(.reshuffleSlotTapped(slot.id)) }
                    )
                }
            }
            .padding(.horizontal, Layout.Padding.screen.leading)
            .padding(.vertical, Spacing.sm)
        }
    }

    // MARK: - Actions

    private var actionButtons: some View {
        VStack(spacing: Spacing.sm) {
            Button {
                Haptics.success()
                store.send(.keepTapped)
            } label: {
                Text("Edit Post")
                    .font(Typography.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(Palette.onAccent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.sm)
                    .background(Palette.accent, in: RoundedRectangle(cornerRadius: Radius.button))
            }
            .buttonStyle(.plain)

            Button {
                Haptics.tap()
                store.send(.remixTapped)
            } label: {
                Label("Remix All", systemImage: "dice")
                    .font(Typography.subheadline)
                    .foregroundStyle(Palette.accent)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.sm)
                    .background(Palette.accentTint, in: RoundedRectangle(cornerRadius: Radius.button))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, Layout.Padding.screen.leading)
        .padding(.vertical, Spacing.sm)
        .background(Palette.surface)
    }
}

// MARK: - Slot Machine Cell

private struct SlotMachineCell: View {
    let slot: FilledSlot
    let index: Int
    let pillars: [PillarSnapshot]
    let blurred: Bool
    let interactive: Bool
    let isReshuffling: Bool
    let onShuffle: () -> Void

    @State private var image: UIImage?
    @State private var contentScale: CGFloat = 1

    private var matchedPillars: [PillarSnapshot] {
        pillars.filter { slot.slotData.pillarIDs.contains($0.id) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            HStack(spacing: Spacing.xs) {
                Text("\(index + 1)")
                    .font(Typography.caption2)
                    .fontWeight(.bold)
                    .foregroundStyle(Palette.accent)
                    .frame(width: 22, height: 22)
                    .background(Palette.accent.opacity(0.15), in: Circle())

                Text(slot.slotData.name)
                    .font(Typography.subheadline)
                    .fontWeight(.medium)
                    .foregroundStyle(Palette.text)

                if !matchedPillars.isEmpty {
                    HStack(spacing: 2) {
                        ForEach(matchedPillars.prefix(3)) { pillar in
                            Text(pillar.emoji)
                                .font(.system(size: 13))
                        }
                        if matchedPillars.count > 0 {
                            Text(matchedPillars.map(\.name).joined(separator: ", "))
                                .font(Typography.caption)
                                .foregroundStyle(Palette.text3)
                                .lineLimit(1)
                        }
                    }
                }

                Spacer()

                if interactive && !slot.isEmpty {
                    Button {
                        Haptics.tap()
                        onShuffle()
                    } label: {
                        Image(systemName: "shuffle")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Palette.accent)
                            .frame(width: 32, height: 32)
                            .background(Palette.accentTint, in: Circle())
                    }
                    .buttonStyle(.plain)
                    .disabled(isReshuffling)
                }
            }

            ZStack {
                Group {
                    if let image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .blur(radius: blurred ? 20 : 0)
                    } else if slot.isEmpty {
                        VStack(spacing: Spacing.xs) {
                            Image(systemName: "photo")
                                .font(.system(size: Typography.IconSize.md))
                                .foregroundStyle(Palette.text4)
                            Text("No match")
                                .font(Typography.caption2)
                                .foregroundStyle(Palette.text3)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Palette.placeholder)
                    } else {
                        Palette.placeholder
                    }
                }
                .scaleEffect(contentScale)

                if !slot.isEmpty {
                    VStack {
                        Spacer()
                        HStack(spacing: Spacing.xxs) {
                            ForEach(slot.slotData.cadrages.prefix(2), id: \.self) { cadrage in
                                CadrageTag(cadrage: cadrage)
                            }
                            if let location = slot.locationLabel ?? slot.slotData.locations.first {
                                HStack(spacing: 2) {
                                    Image(systemName: "mappin")
                                        .font(.system(size: 9))
                                    Text(location)
                                        .font(Typography.caption2)
                                }
                                .foregroundStyle(.white)
                                .padding(.horizontal, Spacing.xs)
                                .padding(.vertical, 2)
                                .background(.black.opacity(0.5), in: Capsule())
                            }
                            Spacer()
                        }
                        .padding(Spacing.xs)
                    }
                    .opacity(contentScale < 0.5 ? 0 : 1)
                }

                if isReshuffling {
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .overlay { ProgressView().tint(Palette.accent) }
                        .transition(.opacity)
                }
            }
            .aspectRatio(4.0 / 3.0, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: Radius.card))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.card)
                    .strokeBorder(Palette.border, lineWidth: Layout.Border.thin)
            )
            .animation(.easeInOut(duration: 0.5), value: blurred)
            .onChange(of: isReshuffling) { oldValue, newValue in
                if !newValue && oldValue {
                    contentScale = 0.01
                    withAnimation(.spring(duration: 0.35, bounce: 0.15)) {
                        contentScale = 1
                    }
                }
            }
        }
        .task(id: slot.photoIDs.first) {
            guard let assetID = slot.photoIDs.first else { return }
            let fetchResult = PHAsset.fetchAssets(
                withLocalIdentifiers: [assetID], options: nil
            )
            guard let asset = fetchResult.firstObject else { return }
            let scale = UIScreen.main.scale
            let width = (UIScreen.main.bounds.width - Layout.Padding.screen.leading * 2)
            let px = ceil(width * scale)
            let size = CGSize(width: px, height: px * 3 / 4)
            let options = PHImageRequestOptions()
            options.deliveryMode = .opportunistic
            options.isNetworkAccessAllowed = false
            PHImageManager.default().requestImage(
                for: asset, targetSize: size,
                contentMode: .aspectFill, options: options
            ) { result, _ in
                guard let result else { return }
                Task { @MainActor in self.image = result }
            }
        }
    }
}
