// MARK: - PostKit
// PaywallFeature.swift — Paywall reducer: product loading, purchase, and restore

import ComposableArchitecture
import Foundation

@Reducer
struct PaywallFeature {
    @ObservableState
    struct State: Equatable {
        var products: [ProProduct] = []
        var selectedProductID: String? = nil
        var isPurchasing: Bool = false
        var isRestoring: Bool = false
        var isLoading: Bool = true
        var errorMessage: String? = nil
    }

    enum Action {
        case onAppear
        case productsLoaded([ProProduct])
        case loadFailed(String)
        case productSelected(String)
        case purchaseTapped
        case purchaseCompleted(success: Bool)
        case restoreTapped
        case restoreCompleted(success: Bool)
        case closeTapped
        case delegate(Delegate)

        enum Delegate: Equatable {
            case didPurchase
            case dismissed
        }
    }

    @Dependency(\.subscription) var subscription
    @Dependency(\.dismiss) var dismiss

    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state.isLoading = true
                return .run { send in
                    let products = try await subscription.fetchProducts()
                    await send(.productsLoaded(products))
                } catch: { error, send in
                    await send(.loadFailed(error.localizedDescription))
                }

            case let .productsLoaded(products):
                state.isLoading = false
                state.products = products
                state.selectedProductID = products.first(where: \.isYearly)?.id ?? products.first?.id
                return .none

            case let .loadFailed(message):
                state.isLoading = false
                state.errorMessage = message
                return .none

            case let .productSelected(id):
                state.selectedProductID = id
                return .none

            case .purchaseTapped:
                guard let productID = state.selectedProductID, !state.isPurchasing else { return .none }
                state.isPurchasing = true
                state.errorMessage = nil
                return .run { send in
                    let success = try await subscription.purchase(productID)
                    await send(.purchaseCompleted(success: success))
                } catch: { _, send in
                    await send(.purchaseCompleted(success: false))
                }

            case let .purchaseCompleted(success):
                state.isPurchasing = false
                if success {
                    return .send(.delegate(.didPurchase))
                }
                return .none

            case .restoreTapped:
                guard !state.isRestoring else { return .none }
                state.isRestoring = true
                state.errorMessage = nil
                return .run { send in
                    try await subscription.restorePurchases()
                    let isPro = await subscription.isProUser()
                    await send(.restoreCompleted(success: isPro))
                } catch: { _, send in
                    await send(.restoreCompleted(success: false))
                }

            case let .restoreCompleted(success):
                state.isRestoring = false
                if success {
                    return .send(.delegate(.didPurchase))
                }
                state.errorMessage = "No active subscription found."
                return .none

            case .closeTapped:
                return .run { _ in await dismiss() }

            case .delegate:
                return .none
            }
        }
    }
}
