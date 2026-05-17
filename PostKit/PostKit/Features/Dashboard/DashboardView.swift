import AudioToolbox
import ComposableArchitecture
import SwiftUI

struct DashboardView: View {
    @Bindable var store: StoreOf<DashboardFeature>

    var body: some View {
        ScrollView {
            VStack(spacing: Spacing.lg) {
                metricsRow
                pillarsSection
            }
            .screenPadding()
        }
        .background(Palette.bg)
        .overlay(alignment: .bottom) {
            if store.isScanning {
                scanProgressBar
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .overlay(alignment: .top) {
            if store.showScanCompleteToast {
                ScanCompleteToast(photoCount: store.totalPhotosSorted)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .padding(.top, Spacing.md)
                    .onAppear {
                        UINotificationFeedbackGenerator().notificationOccurred(.success)
                        AudioServicesPlaySystemSound(1315)
                    }
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: store.isScanning)
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: store.showScanCompleteToast)
        .navigationTitle(AppStrings.Dashboard.title)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    store.send(.addPillarTapped)
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .task { await store.send(.onAppear).finish() }
    }

    private var metricsRow: some View {
        HStack(spacing: Spacing.md) {
            StatCard(
                value: store.totalPhotosSorted,
                label: "Photos sorted",
                delta: nil
            )
            StatCard(
                value: store.pillars.count,
                label: "Active pillars",
                delta: nil,
                tint: Palette.purple
            )
        }
    }

    @ViewBuilder
    private var pillarsSection: some View {
        if store.pillars.isEmpty {
            EmptyStateView(
                icon: "📌",
                title: "No pillars yet",
                message: "Add your first content pillar to get started.",
                actionTitle: "Add Pillar",
                onAction: { store.send(.addPillarTapped) }
            )
            .padding(.top, Spacing.xxl)
        } else {
            SectionHeader(title: "Your Pillars")

            LazyVStack(spacing: Spacing.sm) {
                ForEach(store.pillars) { pillar in
                    Button {
                        store.send(.pillarTapped(pillar))
                    } label: {
                        PillarRowView(pillar: pillar)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var scanProgressBar: some View {
        HStack(spacing: Spacing.md) {
            ProgressView()
                .tint(Palette.accent)
            Text("Scanning library…")
                .font(Typography.footnote)
                .foregroundStyle(Palette.text2)
            Spacer()
            Button {
                store.send(.cancelScanTapped)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(Palette.text3)
            }
        }
        .padding(Layout.Padding.card)
        .background(.ultraThinMaterial)
    }
}

// MARK: - Scan Complete Toast

private struct ScanCompleteToast: View {
    let photoCount: Int

    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Palette.green)
                .font(.system(size: 22))
            Text("Scan complete · \(photoCount) photos sorted")
                .font(Typography.subheadline)
                .fontWeight(.medium)
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.sm)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.1), radius: 12, y: 4)
    }
}
