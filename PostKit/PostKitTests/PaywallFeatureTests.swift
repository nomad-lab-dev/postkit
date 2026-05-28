// MARK: - PostKit
// PaywallFeatureTests.swift — Paywall reducer tests: loading, purchase, restore

import ComposableArchitecture
import Foundation
import XCTest
@testable import PostKit

@MainActor
final class PaywallFeatureTests: XCTestCase {

    let mockProducts: [ProProduct] = [
        ProProduct(id: "pro_yearly", displayName: "Yearly", displayPrice: "$79.99", description: "Save 33%", monthlyEquivalent: "6.67", isYearly: true),
        ProProduct(id: "pro_monthly", displayName: "Monthly", displayPrice: "$9.99", description: "Monthly", monthlyEquivalent: nil, isYearly: false),
    ]

    func test_onAppear_loadsProducts() async {
        let store = TestStore(
            initialState: PaywallFeature.State()
        ) {
            PaywallFeature()
        } withDependencies: {
            $0.subscription.fetchProducts = { [mockProducts] in mockProducts }
        }

        await store.send(.onAppear)

        await store.receive(\.productsLoaded) {
            $0.isLoading = false
            $0.products = self.mockProducts
            $0.selectedProductID = "pro_yearly"
        }
    }

    func test_onAppear_emptyProducts_showsError() async {
        let store = TestStore(
            initialState: PaywallFeature.State()
        ) {
            PaywallFeature()
        } withDependencies: {
            $0.subscription.fetchProducts = { [] }
        }

        await store.send(.onAppear)

        await store.receive(\.productsLoaded) {
            $0.isLoading = false
            $0.errorMessage = "No products available. Check that PostKit.storekit is set in Edit Scheme > Run > Options > StoreKit Configuration."
        }
    }

    func test_onAppear_loadFailure_showsError() async {
        struct FetchError: Error, LocalizedError {
            var errorDescription: String? { "Network error" }
        }

        let store = TestStore(
            initialState: PaywallFeature.State()
        ) {
            PaywallFeature()
        } withDependencies: {
            $0.subscription.fetchProducts = { throw FetchError() }
        }

        await store.send(.onAppear)

        await store.receive(\.loadFailed) {
            $0.isLoading = false
            $0.errorMessage = "Network error"
        }
    }

    func test_productSelected_updatesSelection() async {
        var state = PaywallFeature.State()
        state.isLoading = false
        state.products = mockProducts
        state.selectedProductID = "pro_yearly"

        let store = TestStore(initialState: state) {
            PaywallFeature()
        }

        await store.send(.productSelected("pro_monthly")) {
            $0.selectedProductID = "pro_monthly"
        }
    }

    func test_purchaseTapped_success_sendsDelegateDidPurchase() async {
        var state = PaywallFeature.State()
        state.isLoading = false
        state.products = mockProducts
        state.selectedProductID = "pro_monthly"

        let store = TestStore(initialState: state) {
            PaywallFeature()
        } withDependencies: {
            $0.subscription.purchase = { _ in true }
        }

        await store.send(.purchaseTapped) {
            $0.isPurchasing = true
        }

        await store.receive(\.purchaseCompleted) {
            $0.isPurchasing = false
        }

        await store.receive(\.delegate.didPurchase)
    }

    func test_purchaseTapped_cancelled_staysOnPaywall() async {
        var state = PaywallFeature.State()
        state.isLoading = false
        state.products = mockProducts
        state.selectedProductID = "pro_monthly"

        let store = TestStore(initialState: state) {
            PaywallFeature()
        } withDependencies: {
            $0.subscription.purchase = { _ in false }
        }

        await store.send(.purchaseTapped) {
            $0.isPurchasing = true
        }

        await store.receive(\.purchaseCompleted) {
            $0.isPurchasing = false
        }
    }

    func test_purchaseTapped_noSelection_doesNothing() async {
        var state = PaywallFeature.State()
        state.isLoading = false
        state.products = mockProducts
        state.selectedProductID = nil

        let store = TestStore(initialState: state) {
            PaywallFeature()
        }

        await store.send(.purchaseTapped)
    }

    func test_restoreTapped_success_sendsDelegateDidPurchase() async {
        let store = TestStore(
            initialState: PaywallFeature.State()
        ) {
            PaywallFeature()
        } withDependencies: {
            $0.subscription.restorePurchases = {}
            $0.subscription.isProUser = { true }
        }

        await store.send(.restoreTapped) {
            $0.isRestoring = true
        }

        await store.receive(\.restoreCompleted) {
            $0.isRestoring = false
        }

        await store.receive(\.delegate.didPurchase)
    }

    func test_restoreTapped_noSubscription_showsError() async {
        let store = TestStore(
            initialState: PaywallFeature.State()
        ) {
            PaywallFeature()
        } withDependencies: {
            $0.subscription.restorePurchases = {}
            $0.subscription.isProUser = { false }
        }

        await store.send(.restoreTapped) {
            $0.isRestoring = true
        }

        await store.receive(\.restoreCompleted) {
            $0.isRestoring = false
            $0.errorMessage = "No active subscription found."
        }
    }
}
