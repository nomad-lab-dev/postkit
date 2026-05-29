// MARK: - PostKit
// ClassificationCardView.swift — Classification card UI: swipeable photo card with pillar assignment

import ComposableArchitecture
import SwiftUI

struct ClassificationCardView: View {
    @Bindable var store: StoreOf<ClassificationCardFeature>
    @Dependency(\.photoLibrary) var photoLibrary
    @State private var currentImage: UIImage?
    @State private var dragOffset: CGSize = .zero
    @State private var cardRotation: Double = 0
    @State private var flyingOut: Bool = false

    private let cardCornerRadius: CGFloat = 20

    var body: some View {
        GeometryReader { geo in
            let cardWidth = max(geo.size.width * 0.92, 1)
            let cardHeight = max(geo.size.height - geo.safeAreaInsets.bottom - 8, 1)

            ZStack {
                if store.isComplete {
                    completionView
                } else {
                    cardStack(width: cardWidth, height: cardHeight)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Palette.bg)
        .navigationBarTitleDisplayMode(.inline)
        .task { await store.send(.onAppear).finish() }
        .task(id: store.imageLoadToken) {
            currentImage = nil
            guard let photo = store.currentPhoto else { return }
            let side = UIScreen.main.bounds.width * UIScreen.main.scale
            let size = CGSize(width: side, height: side)
            currentImage = try? await photoLibrary.image(photo.assetLocalIdentifier, size)
            store.send(.imageLoaded)
        }
    }

    // MARK: - Card Stack

    private func cardStack(width: CGFloat, height: CGFloat) -> some View {
        ZStack {
            if store.currentIndex + 1 < store.photos.count {
                backCard(width: width, height: height)
            }

            photoCard(width: width, height: height)
                .offset(x: dragOffset.width)
                .rotationEffect(.degrees(cardRotation))
                .gesture(swipeGesture)
        }
    }

    private func backCard(width: CGFloat, height: CGFloat) -> some View {
        ZStack {
            Palette.surface
            Image(systemName: "photo")
                .font(.system(size: 40))
                .foregroundStyle(Palette.text4)
        }
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: cardCornerRadius))
        .shadow(color: .black.opacity(0.08), radius: 6, y: 4)
        .scaleEffect(dragProgress * 0.05 + 0.93)
        .opacity(dragProgress * 0.3 + 0.6)
        .allowsHitTesting(false)
    }

    private var dragProgress: CGFloat {
        min(abs(dragOffset.width) / 120, 1)
    }

    // MARK: - Photo Card

    private func photoCard(width: CGFloat, height: CGFloat) -> some View {
        ZStack {
            if let image = currentImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: width, height: height)
                    .clipped()
            } else {
                Palette.placeholder
                    .frame(width: width, height: height)
                    .overlay(ProgressView())
            }

            VStack(spacing: 0) {
                topOverlay
                Spacer()
                bottomOverlay
            }

            if dragOffset.width > 30, store.canConfirm {
                swipeFeedback(icon: "checkmark.circle.fill", color: Palette.green)
            } else if dragOffset.width < -30 {
                swipeFeedback(icon: "xmark.circle.fill", color: Palette.red)
            }
        }
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: cardCornerRadius))
        .shadow(color: .black.opacity(0.15), radius: 12, y: 6)
    }

    // MARK: - Top Overlay

    private var topOverlay: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                if let photo = store.currentPhoto {
                    ConfidenceBadge(result: ClassificationResult(
                        pillarName: store.suggestedPillar?.name ?? "Unknown",
                        confidence: photo.confidence,
                        suggestedTags: photo.tags,
                        source: photo.classifiedByAI ? .coreML : .gemini
                    ))
                    .shadow(color: .black.opacity(0.3), radius: 4, y: 2)

                    if let cadrage = photo.cadrage, cadrage != .any {
                        CadrageTag(cadrage: cadrage)
                            .shadow(color: .black.opacity(0.3), radius: 4, y: 2)
                    }
                }
            }

            Spacer()

            Text("\(store.remainingCount) left")
                .font(Typography.subheadline)
                .fontWeight(.semibold)
                .monospacedDigit()
                .foregroundStyle(.white)
                .padding(.horizontal, Spacing.xs)
                .padding(.vertical, Spacing.xxs)
                .background(.ultraThinMaterial, in: Capsule())
        }
        .padding(Spacing.md)
    }

    // MARK: - Bottom Overlay

    private var bottomOverlay: some View {
        VStack(spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                if store.selectedPillars.isEmpty {
                    Text("Select a topic")
                        .font(Typography.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.white.opacity(0.7))
                } else {
                    HStack(spacing: Spacing.xs) {
                        ForEach(store.selectedPillars) { pillar in
                            Text("\(pillar.emoji) \(pillar.name)")
                                .font(Typography.subheadline)
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                        }
                    }
                }

                pillarChips

                if let photo = store.currentPhoto, !photo.tags.isEmpty {
                    HStack(spacing: Spacing.xxs) {
                        ForEach(photo.tags.prefix(3), id: \.self) { tag in
                            Text(tag)
                                .font(Typography.caption)
                                .foregroundStyle(.white.opacity(0.8))
                                .padding(.horizontal, Spacing.xs)
                                .padding(.vertical, 3)
                                .background(.white.opacity(0.15), in: Capsule())
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            actionButtons
        }
        .padding(Spacing.md)
        .padding(.bottom, Spacing.sm)
        .background(
            LinearGradient(
                colors: [.clear, .black.opacity(0.75)],
                startPoint: .top,
                endPoint: .bottom
            )
            .clipShape(
                UnevenRoundedRectangle(
                    bottomLeadingRadius: cardCornerRadius,
                    bottomTrailingRadius: cardCornerRadius
                )
            )
        )
    }

    // MARK: - Pillar Chips

    private let chipColumns = Array(
        repeating: GridItem(.flexible(), spacing: Spacing.xs),
        count: 2
    )

    private var pillarChips: some View {
        LazyVGrid(columns: chipColumns, spacing: Spacing.xs) {
            ForEach(store.pillars) { pillar in
                Button {
                    Haptics.selection()
                    store.send(.pillarSelected(pillar.id))
                } label: {
                    let isSelected = store.selectedPillarIDs.contains(pillar.id)
                    HStack(spacing: 4) {
                        Text(pillar.emoji)
                            .font(.system(size: 14))
                        Text(pillar.name)
                            .font(Typography.footnote)
                            .fontWeight(isSelected ? .bold : .medium)
                            .lineLimit(1)
                        if isSelected {
                            Image(systemName: "xmark")
                                .font(.system(size: 10, weight: .bold))
                        }
                    }
                    .foregroundStyle(isSelected ? .white : .white.opacity(0.85))
                    .padding(.horizontal, Spacing.sm)
                    .padding(.vertical, Spacing.xxs + 2)
                    .frame(maxWidth: .infinity)
                    .background(
                        isSelected ? Palette.accent : .white.opacity(0.2),
                        in: Capsule()
                    )
                    .overlay(
                        Capsule()
                            .strokeBorder(
                                isSelected ? Palette.accent : .white.opacity(0.3),
                                lineWidth: 1
                            )
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Swipe Feedback

    private func swipeFeedback(icon: String, color: Color) -> some View {
        RoundedRectangle(cornerRadius: cardCornerRadius)
            .stroke(color, lineWidth: 3)
            .overlay(
                Image(systemName: icon)
                    .font(.system(size: 72))
                    .foregroundStyle(color)
                    .opacity(min(abs(dragOffset.width) / 100, 1))
            )
    }

    // MARK: - Action Buttons

    private var actionButtons: some View {
        HStack(spacing: Spacing.xl) {
            Button {
                guard !flyingOut else { return }
                dismissCard(direction: -1) { store.send(.rejectTapped) }
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 56, height: 56)
                    .background(Palette.red, in: Circle())
                    .shadow(color: Palette.red.opacity(0.4), radius: 8, y: 3)
            }

            Button { Haptics.lightTap(); store.send(.undoTapped) } label: {
                Image(systemName: "arrow.uturn.backward")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.8))
                    .frame(width: 44, height: 44)
                    .background(.white.opacity(0.2), in: Circle())
            }
            .disabled(!store.canUndo)
            .opacity(store.canUndo ? 1 : 0.3)

            Button {
                guard !flyingOut, store.canConfirm else { return }
                dismissCard(direction: 1) { store.send(.confirmTapped) }
            } label: {
                Image(systemName: "checkmark")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 56, height: 56)
                    .background(
                        store.canConfirm ? Palette.green : .white.opacity(0.15),
                        in: Circle()
                    )
                    .shadow(
                        color: store.canConfirm ? Palette.green.opacity(0.4) : .clear,
                        radius: 8, y: 3
                    )
            }
            .disabled(!store.canConfirm)
        }
    }

    // MARK: - Dismiss Animation

    private func dismissCard(direction: CGFloat, then action: @escaping () -> Void) {
        flyingOut = true
        Haptics.success()
        withAnimation(.easeIn(duration: 0.3)) {
            dragOffset = CGSize(width: direction * 500, height: 0)
            cardRotation = Double(direction) * 15
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            dragOffset = .zero
            cardRotation = 0
            action()
            flyingOut = false
        }
    }

    // MARK: - Completion

    private var completionView: some View {
        VStack(spacing: Spacing.lg) {
            Spacer()

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 72))
                .foregroundStyle(Palette.green)

            Text("All done!")
                .font(Typography.title)

            Text("You've reviewed all pending photos.")
                .font(Typography.body)
                .foregroundStyle(Palette.text3)
                .multilineTextAlignment(.center)

            Spacer()
        }
    }

    // MARK: - Swipe Gesture

    private var swipeGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                guard !flyingOut else { return }
                dragOffset = value.translation
                cardRotation = Double(value.translation.width) / 20
            }
            .onEnded { value in
                guard !flyingOut else { return }
                let didSwipeRight = value.translation.width > 80 && store.canConfirm
                let didSwipeLeft = value.translation.width < -80

                if didSwipeRight {
                    dismissCard(direction: 1) { store.send(.confirmTapped) }
                } else if didSwipeLeft {
                    dismissCard(direction: -1) { store.send(.rejectTapped) }
                } else {
                    withAnimation(.spring(response: 0.3)) {
                        dragOffset = .zero
                        cardRotation = 0
                    }
                }
            }
    }
}
