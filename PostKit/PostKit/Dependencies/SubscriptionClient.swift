// MARK: - PostKit
// SubscriptionClient.swift — StoreKit 2 subscription dependency

import ComposableArchitecture
import os
import StoreKit

private let log = Logger(subsystem: "PostKit", category: "Subscription")

struct ProProduct: Equatable, Identifiable, Sendable {
    let id: String
    let displayName: String
    let displayPrice: String
    let description: String
    let monthlyEquivalent: String?
    let isYearly: Bool
}

private let productIDs = ["pro_monthly", "pro_yearly"]

@DependencyClient
struct SubscriptionClient: Sendable {
    var fetchProducts: @Sendable () async throws -> [ProProduct] = { [] }
    var purchase: @Sendable (_ productID: String) async throws -> Bool = { _ in false }
    var isProUser: @Sendable () async -> Bool = { false }
    var restorePurchases: @Sendable () async throws -> Void
}

extension SubscriptionClient: DependencyKey {
    static let liveValue = SubscriptionClient(
        fetchProducts: {
            log.info("🔍 Requesting products for IDs: \(productIDs)")
            let products = try await Product.products(for: productIDs)
            log.info("📦 StoreKit returned \(products.count) products: \(products.map(\.id))")
            return products.compactMap { product in
                let isYearly = product.id == "pro_yearly"
                let monthlyEquivalent: String? = if isYearly {
                    product.price / 12 > 0
                        ? String(format: "%.2f", NSDecimalNumber(decimal: product.price / 12).doubleValue)
                        : nil
                } else {
                    nil
                }
                return ProProduct(
                    id: product.id,
                    displayName: product.displayName,
                    displayPrice: product.displayPrice,
                    description: product.description,
                    monthlyEquivalent: monthlyEquivalent,
                    isYearly: isYearly
                )
            }
            .sorted { $0.isYearly && !$1.isYearly }
        },
        purchase: { productID in
            guard let product = try await Product.products(for: [productID]).first else {
                return false
            }
            let result = try await product.purchase()
            switch result {
            case let .success(verification):
                switch verification {
                case let .verified(transaction):
                    await transaction.finish()
                    return true
                case .unverified:
                    return false
                }
            case .userCancelled, .pending:
                return false
            @unknown default:
                return false
            }
        },
        isProUser: {
            for await verificationResult in Transaction.currentEntitlements {
                guard case let .verified(transaction) = verificationResult else { continue }
                if productIDs.contains(transaction.productID) {
                    return true
                }
            }
            return false
        },
        restorePurchases: {
            try await AppStore.sync()
        }
    )

    static let previewValue = SubscriptionClient(
        fetchProducts: {
            [
                ProProduct(id: "pro_monthly", displayName: "Monthly", displayPrice: "$9.99", description: "PostKit Pro Monthly", monthlyEquivalent: nil, isYearly: false),
                ProProduct(id: "pro_yearly", displayName: "Yearly", displayPrice: "$79.99", description: "PostKit Pro Yearly", monthlyEquivalent: "6.67", isYearly: true),
            ]
        },
        purchase: { _ in true },
        isProUser: { false },
        restorePurchases: {}
    )
}

extension DependencyValues {
    var subscription: SubscriptionClient {
        get { self[SubscriptionClient.self] }
        set { self[SubscriptionClient.self] = newValue }
    }
}
