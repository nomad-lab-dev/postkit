// MARK: - PostKit
// PhotoDetailView.swift — Full-screen photo viewer with pinch-to-zoom and pillar editing

import ComposableArchitecture
@preconcurrency import Photos
import SwiftUI

struct PhotoDetailView: View {
    @Bindable var store: StoreOf<PhotoDetailFeature>

    @State private var image: UIImage?
    @State private var showCopied = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Palette.bg.ignoresSafeArea()

                if let image {
                    ZoomableImage(image: image, size: geo.size)
                } else {
                    ProgressView()
                        .tint(Palette.text3)
                }

                VStack {
                    Spacer()
                    metadataOverlay
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Haptics.tap()
                    store.send(.copyTapped)
                    withAnimation { showCopied = true }
                } label: {
                    Image(systemName: showCopied ? "checkmark" : "doc.on.doc")
                        .foregroundStyle(Palette.text)
                }
            }
        }
        .sheet(isPresented: Binding(
            get: { store.showPillarPicker },
            set: { _ in store.send(.pillarPickerToggled) }
        )) {
            PillarPickerSheet(
                pillars: store.availablePillars,
                onSelect: { store.send(.addPillarTapped($0)) }
            )
            .presentationDetents([.medium])
        }
        .task {
            await loadFullImage()
        }
        .onChange(of: showCopied) { _, show in
            if show {
                Task {
                    try? await Task.sleep(for: .seconds(1.5))
                    withAnimation { showCopied = false }
                }
            }
        }
    }

    private var metadataOverlay: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            pillarChips

            HStack(spacing: Spacing.md) {
                if let cadrage = store.photo.cadrage, cadrage != .any {
                    Label(cadrage.rawValue.capitalized, systemImage: "camera.viewfinder")
                }
                if let location = store.photo.location {
                    Label(location, systemImage: "mappin")
                }
                if let date = store.photo.capturedAt {
                    Label(date.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
                }
            }
            .font(Typography.caption)
            .foregroundStyle(Palette.text3)

            if !store.photo.tags.isEmpty {
                FlowLayout(spacing: Spacing.xxs) {
                    ForEach(store.photo.tags.prefix(8), id: \.self) { tag in
                        Text(tag)
                            .font(Typography.caption2)
                            .foregroundStyle(Palette.text3)
                            .padding(.horizontal, Spacing.xs)
                            .padding(.vertical, 2)
                            .background(Palette.surface, in: Capsule())
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Layout.Padding.screen)
        .background(
            LinearGradient(
                colors: [.clear, Palette.bg.opacity(0.9)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    @ViewBuilder
    private var pillarChips: some View {
        FlowLayout(spacing: Spacing.xs) {
            ForEach(store.assignedPillars) { pillar in
                HStack(spacing: Spacing.xxs) {
                    Text(pillar.emoji)
                    Text(pillar.name)
                        .fontWeight(.semibold)
                    Button {
                        Haptics.lightTap()
                        store.send(.removePillarTapped(pillar.id))
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(Palette.text3)
                    }
                }
                .font(Typography.subheadline)
                .foregroundStyle(Palette.text)
                .padding(.horizontal, Spacing.sm)
                .padding(.vertical, Spacing.xxs + 2)
                .background(Palette.accentTint, in: Capsule())
                .overlay(Capsule().strokeBorder(Palette.accent.opacity(0.3), lineWidth: 1))
            }

            Button {
                Haptics.lightTap()
                store.send(.pillarPickerToggled)
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Palette.accent)
                    .frame(width: 30, height: 30)
                    .background(Palette.accentTint, in: Circle())
                    .overlay(Circle().strokeBorder(Palette.accent.opacity(0.3), lineWidth: 1))
            }
        }
    }

    private func loadFullImage() async {
        let fetchResult = PHAsset.fetchAssets(
            withLocalIdentifiers: [store.photo.assetLocalIdentifier], options: nil
        )
        guard let asset = fetchResult.firstObject else { return }
        let size = CGSize(
            width: UIScreen.main.bounds.width * UIScreen.main.scale,
            height: UIScreen.main.bounds.height * UIScreen.main.scale
        )
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        PHImageManager.default().requestImage(
            for: asset, targetSize: size,
            contentMode: .aspectFit, options: options
        ) { result, _ in
            guard let result else { return }
            Task { @MainActor in self.image = result }
        }
    }
}

// MARK: - Zoomable Image

private struct ZoomableImage: View {
    let image: UIImage
    let size: CGSize

    @State private var scale: CGFloat = 1
    @State private var lastScale: CGFloat = 1
    @State private var offset: CGOffset = .zero
    @State private var lastOffset: CGOffset = .zero

    var body: some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFit()
            .scaleEffect(scale)
            .offset(x: offset.width, y: offset.height)
            .gesture(magnification)
            .gesture(drag)
            .onTapGesture(count: 2) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    if scale > 1.1 {
                        scale = 1
                        lastScale = 1
                        offset = .zero
                        lastOffset = .zero
                    } else {
                        scale = 2.5
                        lastScale = 2.5
                    }
                }
            }
    }

    private var magnification: some Gesture {
        MagnifyGesture()
            .onChanged { value in
                let newScale = lastScale * value.magnification
                scale = max(1, min(newScale, 5))
            }
            .onEnded { value in
                let newScale = lastScale * value.magnification
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    scale = max(1, min(newScale, 5))
                    if scale <= 1.05 {
                        scale = 1
                        offset = .zero
                        lastOffset = .zero
                    }
                }
                lastScale = scale
            }
    }

    private var drag: some Gesture {
        DragGesture()
            .onChanged { value in
                guard scale > 1 else { return }
                offset = CGSize(
                    width: lastOffset.width + value.translation.width,
                    height: lastOffset.height + value.translation.height
                )
            }
            .onEnded { value in
                guard scale > 1 else {
                    offset = .zero
                    lastOffset = .zero
                    return
                }
                lastOffset = offset
            }
    }
}

private typealias CGOffset = CGSize

// MARK: - Pillar Picker Sheet

private struct PillarPickerSheet: View {
    let pillars: [PillarSnapshot]
    let onSelect: (UUID) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                if pillars.isEmpty {
                    Text("All topics are already assigned")
                        .font(Typography.subheadline)
                        .foregroundStyle(Palette.text3)
                        .listRowBackground(Color.clear)
                } else {
                    ForEach(pillars) { pillar in
                        Button {
                            Haptics.tap()
                            onSelect(pillar.id)
                        } label: {
                            HStack(spacing: Spacing.sm) {
                                Text(pillar.emoji)
                                    .font(.system(size: 24))
                                Text(pillar.name)
                                    .font(Typography.body)
                                    .foregroundStyle(Palette.text)
                                Spacer()
                                Image(systemName: "plus.circle")
                                    .foregroundStyle(Palette.accent)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add to topic")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
