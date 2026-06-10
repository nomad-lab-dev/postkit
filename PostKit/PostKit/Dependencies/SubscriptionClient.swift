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
    let weeklyEquivalent: String?  // per-week cost shown under the annual card
    let savingsPercent: Int?       // yearly card badge — computed vs weekly × 52
    let isYearly: Bool
}

private let productIDs = ["lucchettan.postkit.pro_weekly", "lucchettan.postkit.pro_yearly"]

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
            // savings % is computed cross-product: 1 - (yearly / (weekly × 52))
            let weeklyProduct = products.first { $0.id == "lucchettan.postkit.pro_weekly" }
            let yearlyProduct = products.first { $0.id == "lucchettan.postkit.pro_yearly" }
            let yearlySavingsPercent: Int? = {
                guard let weeklyProduct, let yearlyProduct else { return nil }
                let yearOfWeekly = weeklyProduct.price * 52
                guard yearOfWeekly > 0 else { return nil }
                let ratio = NSDecimalNumber(decimal: yearlyProduct.price / yearOfWeekly).doubleValue
                let percent = Int((1 - ratio) * 100)
                return percent > 0 ? percent : nil
            }()

            return products.compactMap { product in
                let isYearly = product.id == "lucchettan.postkit.pro_yearly"
                // annual plan: show per-week equivalent formatted in the product's currency/locale
                let weeklyEquivalent: String? = isYearly
                    ? (product.price / 52).formatted(product.priceFormatStyle)
                    : nil
                return ProProduct(
                    id: product.id,
                    displayName: product.displayName,
                    displayPrice: product.displayPrice,
                    description: product.description,
                    weeklyEquivalent: weeklyEquivalent,
                    savingsPercent: isYearly ? yearlySavingsPercent : nil,
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
                ProProduct(id: "lucchettan.postkit.pro_yearly", displayName: "Yearly", displayPrice: "$59.99", description: "PostKit Pro Yearly", weeklyEquivalent: "$1.15", savingsPercent: 61, isYearly: true),
                ProProduct(id: "lucchettan.postkit.pro_weekly", displayName: "Weekly", displayPrice: "$2.99", description: "PostKit Pro Weekly", weeklyEquivalent: nil, savingsPercent: nil, isYearly: false),
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
