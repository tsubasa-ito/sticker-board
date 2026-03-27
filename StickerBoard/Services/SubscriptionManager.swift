import Foundation
import StoreKit

@MainActor
final class SubscriptionManager: ObservableObject {
    static let shared = SubscriptionManager()

    @Published private(set) var isProUser: Bool = false
    @Published private(set) var products: [Product] = []
    @Published private(set) var purchasedProductIDs: Set<String> = []
    @Published private(set) var currentSubscriptionExpirationDate: Date?

    enum PlanType {
        case free
        case monthlyPro
        case yearlyPro

        var displayName: String {
            switch self {
            case .free: "無料プラン"
            case .monthlyPro: "Pro（月額）"
            case .yearlyPro: "Pro（年額）"
            }
        }
    }

    var currentPlan: PlanType {
        if purchasedProductIDs.contains(SubscriptionProduct.yearlyPro.rawValue) {
            return .yearlyPro
        } else if purchasedProductIDs.contains(SubscriptionProduct.monthlyPro.rawValue) {
            return .monthlyPro
        }
        return .free
    }

    private var transactionListener: Task<Void, Never>?

    var monthlyProduct: Product? {
        products.first { $0.id == SubscriptionProduct.monthlyPro.rawValue }
    }

    var yearlyProduct: Product? {
        products.first { $0.id == SubscriptionProduct.yearlyPro.rawValue }
    }

    /// 年額プランの月あたり価格（表示用文字列）
    var yearlyMonthlyPrice: String? {
        guard let yearly = yearlyProduct else { return nil }
        let monthly = yearly.price / 12
        return monthly.formatted(.currency(code: "JPY"))
    }

    /// 年額プランの割引率（月額比）
    var savingsPercentage: Int {
        guard let monthly = monthlyProduct, let yearly = yearlyProduct else { return 0 }
        let yearlyTotal = yearly.price
        let monthlyTotal = monthly.price * 12
        guard monthlyTotal > 0 else { return 0 }
        let savings = ((monthlyTotal - yearlyTotal) / monthlyTotal * 100) as NSDecimalNumber
        return savings.intValue
    }

    private init() {
        isProUser = UserDefaults.standard.bool(forKey: "isProUser_cached")
        transactionListener = listenForTransactions()

        Task {
            await loadProducts()
            await updatePurchasedProducts()
        }
    }

    deinit {
        transactionListener?.cancel()
    }

    // MARK: - 商品読み込み

    func loadProducts() async {
        do {
            let ids = SubscriptionProduct.allIdentifiers
            print("[SubscriptionManager] Loading products for IDs: \(ids)")
            let storeProducts = try await Product.products(for: ids)
            print("[SubscriptionManager] Loaded \(storeProducts.count) products: \(storeProducts.map { "\($0.id) - \($0.displayPrice)" })")
            products = storeProducts.sorted { $0.price > $1.price }
        } catch {
            print("[SubscriptionManager] Failed to load products: \(error)")
        }
    }

    // MARK: - 購入

    enum PurchaseResult {
        case success
        case cancelled
        case pending
        case failed(Error)
    }

    func purchase(_ product: Product) async -> PurchaseResult {
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
                await updatePurchasedProducts()
                return .success
            case .userCancelled:
                return .cancelled
            case .pending:
                return .pending
            @unknown default:
                return .cancelled
            }
        } catch {
            return .failed(error)
        }
    }

    // MARK: - 購入復元

    func restorePurchases() async throws {
        try await AppStore.sync()
        await updatePurchasedProducts()
    }

    // MARK: - 購入状態の更新

    func updatePurchasedProducts() async {
        var purchased: Set<String> = []
        var latestExpiration: Date?

        for await result in Transaction.currentEntitlements {
            do {
                let transaction = try checkVerified(result)
                if transaction.revocationDate != nil {
                    continue
                }
                if let expirationDate = transaction.expirationDate, expirationDate < Date() {
                    continue
                }
                purchased.insert(transaction.productID)
                if let expDate = transaction.expirationDate {
                    if let current = latestExpiration {
                        latestExpiration = max(current, expDate)
                    } else {
                        latestExpiration = expDate
                    }
                }
            } catch {
                print("[SubscriptionManager] Failed to verify transaction while updating purchased products: \(error)")
            }
        }

        purchasedProductIDs = purchased
        currentSubscriptionExpirationDate = latestExpiration
        let isPro = !purchased.isEmpty
        isProUser = isPro
        UserDefaults.standard.set(isPro, forKey: "isProUser_cached")
    }

    // MARK: - トランザクション監視

    private func listenForTransactions() -> Task<Void, Never> {
        Task(priority: .background) {
            for await result in Transaction.updates {
                do {
                    let transaction = try checkVerified(result)
                    await transaction.finish()
                    await updatePurchasedProducts()
                } catch {
                    print("[SubscriptionManager] Failed to verify transaction from updates: \(error)")
                }
            }
        }
    }

    // MARK: - 検証

    private nonisolated func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw error
        case .verified(let safe):
            return safe
        }
    }
}
