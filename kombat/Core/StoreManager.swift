//
//  StoreManager.swift
//  kombat
//

import StoreKit

enum StoreError: LocalizedError {
    case failedVerification
    var errorDescription: String? { "Purchase could not be verified." }
}

@MainActor
final class StoreManager: ObservableObject {
    static let monthlyProductID = "com.rexordonez.kombat.premium.monthly"

    @Published private(set) var product: Product?
    @Published private(set) var isSubscribed = false
    @Published private(set) var isLoading = false
    @Published var errorMessage: String?

    private var updatesTask: Task<Void, Never>?

    init() {
        updatesTask = listenForTransactionUpdates()
        Task {
            await loadProduct()
            await refreshEntitlementsWithSyncFallback()
        }
    }

    deinit {
        updatesTask?.cancel()
    }

    func loadProduct() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let products = try await Product.products(for: [Self.monthlyProductID])
            if let first = products.first {
                product = first
                errorMessage = nil
            } else {
                product = nil
                errorMessage = "Subscription not available yet. If you just created it in App Store Connect, it can take a few hours to activate — try again shortly."
            }
        } catch {
            errorMessage = "Couldn't load subscription info: \(error.localizedDescription)"
        }
    }

    func purchase() async {
        guard let product else { return }
        errorMessage = nil
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = try checkVerified(verification)
                await transaction.finish()
            case .userCancelled, .pending:
                break
            @unknown default:
                break
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        // Always re-check, even on failure: an "already subscribed" error, for
        // instance, means there's a real entitlement we just weren't reflecting yet.
        await refreshEntitlementsWithSyncFallback()
    }

    func restorePurchases() async {
        try? await AppStore.sync()
        await refreshEntitlements()
    }

    /// Transaction.currentEntitlements reads a local cache that can lag behind a
    /// real purchase — especially with local StoreKit testing on a real device,
    /// where it can come back completely empty even right after a successful
    /// purchase. If the fast path finds nothing, force a sync with the App
    /// Store and check once more before giving up.
    private func refreshEntitlementsWithSyncFallback() async {
        await refreshEntitlements()
        guard !isSubscribed else { return }
        try? await AppStore.sync()
        await refreshEntitlements()
    }

    private func refreshEntitlements() async {
        var subscribed = false
        var entitlementCount = 0
        var verificationFailures = 0
        var seenProductIDs: [String] = []

        for await result in Transaction.currentEntitlements {
            entitlementCount += 1
            do {
                let transaction = try checkVerified(result)
                seenProductIDs.append(transaction.productID)
                if transaction.productID == Self.monthlyProductID {
                    subscribed = true
                }
            } catch {
                verificationFailures += 1
            }
        }

        isSubscribed = subscribed
        #if DEBUG
        print("[StoreManager] refreshEntitlements: \(entitlementCount) entitlement(s), \(verificationFailures) failed verification, productIDs seen: \(seenProductIDs), expecting: \(Self.monthlyProductID), isSubscribed: \(subscribed)")
        #endif
    }

    private func listenForTransactionUpdates() -> Task<Void, Never> {
        Task { [weak self] in
            for await result in Transaction.updates {
                guard let self, let transaction = try? self.checkVerified(result) else { continue }
                await transaction.finish()
                await self.refreshEntitlements()
            }
        }
    }

    private nonisolated func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
}
