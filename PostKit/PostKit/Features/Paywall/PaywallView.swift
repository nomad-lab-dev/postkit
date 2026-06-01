// MARK: - PostKit
// PaywallView.swift — Subscription paywall UI

import ComposableArchitecture
import SwiftUI

struct PaywallView: View {
    @Bindable var store: StoreOf<PaywallFeature>

    var body: some View {
        ZStack {
            Palette.bg.ignoresSafeArea()

            if store.isLoading {
                ProgressView()
                    .tint(Palette.text3)
            } else {
                ScrollView {
                    VStack(spacing: Spacing.xl) {
                        heroSection
                        benefitsList
                        productCards
                        ctaSection
                        legalSection
                    }
                    .padding(Layout.Padding.screen)
                }
            }
        }
        .overlay(alignment: .topTrailing) {
            Button { store.send(.closeTapped) } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(Palette.text3)
            }
            .padding(Spacing.md)
        }
        .task { store.send(.onAppear) }
    }

    // MARK: - Hero

    private var heroSection: some View {
        VStack(spacing: Spacing.md) {
            Image(systemName: "crown.fill")
                .font(.system(size: 56))
                .foregroundStyle(Palette.accent)
                .padding(.top, Spacing.xxl)

            Text("Unlock PostKit Pro")
                .font(Typography.title)
                .fontWeight(.bold)
                .foregroundStyle(Palette.text)

            Text("Unlimited AI posts, every day.")
                .font(Typography.body)
                .foregroundStyle(Palette.text3)
        }
    }

    // MARK: - Benefits

    private var benefitsList: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            benefitRow("Unlimited photo scanning")
            benefitRow("Unlimited AI captions & hashtags")
            benefitRow("Unlimited social sharing")
            benefitRow("Unlimited templates & pillars")
            benefitRow("Platform-adapted tone")
        }
        .padding(Spacing.lg)
        .background(Palette.surface, in: RoundedRectangle(cornerRadius: Radius.card))
    }

    private func benefitRow(_ text: LocalizedStringKey) -> some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Palette.green)
                .font(.system(size: 20))
            Text(text)
                .font(Typography.body)
                .foregroundStyle(Palette.text)
        }
    }

    // MARK: - Product Cards

    private var productCards: some View {
        VStack(spacing: Spacing.sm) {
            ForEach(store.products) { product in
                Button { store.send(.productSelected(product.id)) } label: {
                    productCard(product)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func productCard(_ product: ProProduct) -> some View {
        let isSelected = store.selectedProductID == product.id

        return HStack {
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                HStack(spacing: Spacing.xs) {
                    Text(product.displayName)
                        .font(Typography.headline)
                        .foregroundStyle(Palette.text)
                    if product.isYearly {
                        Text("SAVE 74%")
                            .font(Typography.caption2)
                            .fontWeight(.bold)
                            .foregroundStyle(.white)
                            .padding(.horizontal, Spacing.xs)
                            .padding(.vertical, 2)
                            .background(Palette.green, in: Capsule())
                    }
                }
                if let weekly = product.weeklyEquivalent {
                    Text("$\(weekly)/wk")
                        .font(Typography.caption)
                        .foregroundStyle(Palette.text3)
                }
            }

            Spacer()

            Text(product.displayPrice)
                .font(Typography.title3)
                .fontWeight(.bold)
                .foregroundStyle(isSelected ? Palette.accent : Palette.text)
        }
        .padding(Spacing.lg)
        .background(
            isSelected ? Palette.accentTint : Palette.surface,
            in: RoundedRectangle(cornerRadius: Radius.card)
        )
        .overlay(
            RoundedRectangle(cornerRadius: Radius.card)
                .strokeBorder(
                    isSelected ? Palette.accent : Palette.border,
                    lineWidth: isSelected ? 2 : 1
                )
        )
    }

    // MARK: - CTA

    private var ctaSection: some View {
        VStack(spacing: Spacing.md) {
            Button {
                Haptics.tap()
                store.send(.purchaseTapped)
            } label: {
                if store.isPurchasing {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Start Free Trial")
                }
            }
            .buttonStyle(PrimaryButton())
            .disabled(store.isPurchasing || store.selectedProductID == nil)

            Button {
                store.send(.restoreTapped)
            } label: {
                if store.isRestoring {
                    ProgressView()
                        .tint(Palette.text3)
                } else {
                    Text("Restore Purchases")
                        .font(Typography.subheadline)
                        .foregroundStyle(Palette.text3)
                }
            }
            .disabled(store.isRestoring)

            if let error = store.errorMessage {
                Text(error)
                    .font(Typography.caption)
                    .foregroundStyle(Palette.red)
            }
        }
    }

    // MARK: - Legal

    private var legalSection: some View {
        Text("7-day free trial, then auto-renews. Cancel anytime at least 24 hours before the end of the current period. Manage in Settings > Apple ID > Subscriptions.")
            .font(Typography.caption2)
            .foregroundStyle(Palette.text4)
            .multilineTextAlignment(.center)
            .padding(.bottom, Spacing.lg)
    }
}

private let mockProducts = [
    ProProduct(id: "lucchettan.postkit.pro_weekly", displayName: "Weekly", displayPrice: "$2.99", description: "Weekly Pro", weeklyEquivalent: nil, isYearly: false),
    ProProduct(id: "lucchettan.postkit.pro_yearly", displayName: "Yearly", displayPrice: "$39.99", description: "Yearly Pro", weeklyEquivalent: "0.77", isYearly: true),
]

#Preview("Yearly selected") {
    PaywallView(store: Store(initialState: PaywallFeature.State(
        products: mockProducts,
        selectedProductID: "lucchettan.postkit.pro_yearly",
        isLoading: false
    )) {
        Reduce { _, _ in .none }
    })
}

#Preview("Weekly selected") {
    PaywallView(store: Store(initialState: PaywallFeature.State(
        products: mockProducts,
        selectedProductID: "lucchettan.postkit.pro_weekly",
        isLoading: false
    )) {
        Reduce { _, _ in .none }
    })
}
