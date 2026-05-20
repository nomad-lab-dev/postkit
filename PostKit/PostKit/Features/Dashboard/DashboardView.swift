import ComposableArchitecture
import SwiftUI

struct DashboardView: View {
    @Bindable var store: StoreOf<DashboardFeature>
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack(alignment: .bottom) {
            if store.isInitialLoading {
                dashboardSkeleton
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: Spacing.lg) {
                        DashboardStatusBanner(
                            status: store.derivedStatus,
                            onPrimary: { store.send(.statusPrimaryTapped) }
                        )
                        .padding(.top, Spacing.xs)

                        if !store.scheduledTemplates.isEmpty {
                            PlannedTodaySection(
                                templates: store.scheduledTemplates,
                                now: Date(),
                                onTap: { store.send(.scheduledTemplateTapped($0)) }
                            )
                        } else {
                            TemplateNudgeCard {
                                store.send(.composePostTapped)
                            }
                        }

                        if store.pillars.isEmpty {
                            EmptyPillarsState { store.send(.addPillarTapped) }
                        } else {
                            PillarsBentoSection(
                                pillars: store.pillars,
                                onTap: { store.send(.pillarTapped($0)) }
                            )
                        }

                        QuickActionsSection(
                            onCompose: { store.send(.composePostTapped) },
                            onNewTemplate: { store.send(.newTemplateTapped) }
                        )

                        Spacer(minLength: Spacing.xxl)
                    }
                    .padding(.horizontal, Spacing.lg)
                }
                .scrollIndicators(.hidden)
                .refreshable { await store.send(.pullToRefresh).finish() }
            }

            if store.showScanCompleteToast {
                ScanCompleteToast()
                    .padding(.horizontal, Spacing.lg)
                    .padding(.bottom, Spacing.md)
                    .transition(.asymmetric(
                        insertion: .move(edge: .bottom).combined(with: .opacity),
                        removal: .opacity
                    ))
            }
        }
        .background(Palette.bg.ignoresSafeArea())
        .navigationTitle("Dashboard")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                ScanStatusTag(
                    remaining: store.remainingToScan,
                    isScanning: store.isScanning,
                    onTap: { store.send(.startFullScanRequested) }
                )
            }
        }
        .task { await store.send(.onAppear).finish() }
        .navigationDestination(item: $store.scope(state: \.detail, action: \.detail)) { detailStore in
            PillarDetailView(store: detailStore)
        }
        .sheet(item: $store.scope(state: \.classificationQueue, action: \.classificationQueue)) { queueStore in
            NavigationStack {
                ClassificationQueueView(store: queueStore)
            }
        }
        .sheet(item: $store.scope(state: \.scheduledEditor, action: \.scheduledEditor)) { editorStore in
            NavigationStack {
                PostEditorView(store: editorStore)
            }
        }
        .animation(
            reduceMotion
                ? .easeInOut(duration: 0.2)
                : .spring(response: 0.45, dampingFraction: 0.82),
            value: store.showScanCompleteToast
        )
        .animation(.snappy(duration: 0.35), value: store.derivedStatus)
    }

    private var dashboardSkeleton: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: Spacing.lg) {
                SkeletonRect(height: 60, radius: Radius.card)
                    .padding(.top, Spacing.xs)

                SkeletonRect(height: 80, radius: Radius.card)

                VStack(alignment: .leading, spacing: Spacing.sm) {
                    SkeletonRect(width: 80, height: 14)
                    LazyVGrid(
                        columns: [GridItem(.flexible()), GridItem(.flexible())],
                        spacing: Spacing.sm
                    ) {
                        ForEach(0..<4, id: \.self) { _ in
                            SkeletonRect(height: 90, radius: Radius.card)
                        }
                    }
                }

                HStack(spacing: Spacing.sm) {
                    SkeletonRect(height: 56, radius: Radius.card)
                    SkeletonRect(height: 56, radius: Radius.card)
                }
            }
            .padding(.horizontal, Spacing.lg)
        }
        .scrollIndicators(.hidden)
    }
}

// MARK: - Scan Status Tag

private struct ScanStatusTag: View {
    let remaining: Int
    let isScanning: Bool
    let onTap: () -> Void

    @State private var rotating = false

    var body: some View {
        if isScanning {
            tagContent(
                icon: "arrow.triangle.2.circlepath",
                text: "Scan en cours…",
                color: Palette.accent,
                spinning: true
            )
            .onAppear { rotating = true }
            .onDisappear { rotating = false }
        } else if remaining > 0 {
            Button(action: onTap) {
                tagContent(
                    icon: "viewfinder",
                    text: "\(remaining) à scanner",
                    color: Palette.accent
                )
            }
        } else {
            tagContent(
                icon: "checkmark.circle.fill",
                text: "Galerie triée",
                color: Palette.green
            )
        }
    }

    private func tagContent(icon: String, text: String, color: Color, spinning: Bool = false) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .semibold))
                .rotationEffect(.degrees(rotating && spinning ? 360 : 0))
                .animation(
                    rotating && spinning
                        ? .linear(duration: 1.2).repeatForever(autoreverses: false)
                        : .default,
                    value: rotating
                )
            Text(text)
                .font(Typography.caption.weight(.medium))
        }
        .foregroundStyle(color)
        .padding(.horizontal, Spacing.sm)
        .padding(.vertical, Spacing.xxs + 2)
        .background(color.opacity(0.12), in: Capsule())
    }
}

// MARK: - Previews

#Preview("Idle — all caught up") {
    NavigationStack {
        DashboardView(store: Store(initialState: DashboardFeature.State(
            pillars: IdentifiedArrayOf(uniqueElements: [
                PillarSnapshot(name: "Automotive", emoji: "🚗", photoCount: 47),
                PillarSnapshot(name: "Food", emoji: "🍽️", photoCount: 32),
                PillarSnapshot(name: "Business", emoji: "💼", photoCount: 115),
            ]),
            isInitialLoading: false,
            lastScanCompletedAt: Date().addingTimeInterval(-7200)
        )) {
            DashboardFeature()
        } withDependencies: {
            $0.persistence = .previewValue
            $0.photoLibrary = .previewValue
            $0.imageClassifier = .previewValue
        })
    }
}

#Preview("New items") {
    NavigationStack {
        DashboardView(store: Store(initialState: DashboardFeature.State(
            pillars: IdentifiedArrayOf(uniqueElements: [
                PillarSnapshot(name: "Automotive", emoji: "🚗", photoCount: 47),
            ]),
            isInitialLoading: false,
            newPhotoCount: 47
        )) {
            DashboardFeature()
        })
    }
}

#Preview("Review needed") {
    NavigationStack {
        DashboardView(store: Store(initialState: DashboardFeature.State(
            pillars: IdentifiedArrayOf(uniqueElements: [
                PillarSnapshot(name: "Automotive", emoji: "🚗", photoCount: 47),
            ]),
            isInitialLoading: false,
            pendingReviewCount: 12
        )) {
            DashboardFeature()
        })
    }
}

#Preview("Scanning") {
    NavigationStack {
        DashboardView(store: Store(initialState: DashboardFeature.State(
            pillars: IdentifiedArrayOf(uniqueElements: [
                PillarSnapshot(name: "Automotive", emoji: "🚗", photoCount: 12),
            ]),
            isInitialLoading: false,
            isScanning: true,
            scanProgress: 0.13,
            totalPhotosToScan: 1204
        )) {
            DashboardFeature()
        })
    }
}
