//
//  StoreKitManager.swift
//  ScreenTimeBudget
//
//  Manages StoreKit subscriptions
//

import Foundation
import StoreKit

class StoreKitManager: NSObject, ObservableObject {
    static let shared = StoreKitManager()

    // Product IDs (these need to be created in App Store Connect)
    private let monthlySubscriptionID = "com.campbell.screenbudget.monthly"

    @Published var products: [SKProduct] = []
    @Published var isPurchasing = false
    @Published var subscriptionStatus: SubscriptionState = .none

    enum SubscriptionState {
        case none
        case trial
        case active
        case expired
    }

    private var productsRequest: SKProductsRequest?
    private var purchaseCompletion: ((Result<SKPaymentTransaction, Error>) -> Void)?

    override init() {
        super.init()
        SKPaymentQueue.default().add(self)
        fetchProducts()
    }

    deinit {
        SKPaymentQueue.default().remove(self)
    }

    // MARK: - Fetch Products

    func fetchProducts() {
        let productIDs: Set<String> = [monthlySubscriptionID]
        productsRequest = SKProductsRequest(productIdentifiers: productIDs)
        productsRequest?.delegate = self
        productsRequest?.start()
    }

    // MARK: - Purchase

    func purchase(product: SKProduct) async throws -> SKPaymentTransaction {
        guard SKPaymentQueue.canMakePayments() else {
            throw StoreKitError.cannotMakePurchase
        }

        return try await withCheckedThrowingContinuation { continuation in
            purchaseCompletion = { result in
                continuation.resume(with: result)
            }

            let payment = SKPayment(product: product)
            SKPaymentQueue.default().add(payment)
        }
    }

    // MARK: - Restore Purchases

    func restorePurchases() {
        SKPaymentQueue.default().restoreCompletedTransactions()
    }

    // MARK: - Subscription Status

    func checkSubscriptionStatus() async {
        // In production, you would:
        // 1. Get the receipt data
        // 2. Send to your backend
        // 3. Backend validates with Apple
        // 4. Backend returns subscription status

        // For now, we'll check locally
        if let receiptURL = Bundle.main.appStoreReceiptURL,
           FileManager.default.fileExists(atPath: receiptURL.path) {
            // Receipt exists - user has purchased
            // You would validate this with your backend
            subscriptionStatus = .active
        } else {
            subscriptionStatus = .none
        }
    }

    // MARK: - Price Formatting

    func formattedPrice(for product: SKProduct) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = product.priceLocale
        return formatter.string(from: product.price) ?? "$0.99"
    }
}

// MARK: - SKProductsRequestDelegate

extension StoreKitManager: SKProductsRequestDelegate {
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        DispatchQueue.main.async {
            self.products = response.products
        }

        if !response.invalidProductIdentifiers.isEmpty {
            print("Invalid product IDs: \(response.invalidProductIdentifiers)")
        }
    }

    func request(_ request: SKRequest, didFailWithError error: Error) {
        print("Failed to fetch products: \(error.localizedDescription)")
    }
}

// MARK: - SKPaymentTransactionObserver

extension StoreKitManager: SKPaymentTransactionObserver {
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased:
                handlePurchased(transaction)
            case .failed:
                handleFailed(transaction)
            case .restored:
                handleRestored(transaction)
            case .deferred, .purchasing:
                break
            @unknown default:
                break
            }
        }
    }

    private func handlePurchased(_ transaction: SKPaymentTransaction) {
        // Unlock content
        subscriptionStatus = .active

        // Send receipt to backend
        sendReceiptToBackend(transaction: transaction)

        // Finish transaction
        SKPaymentQueue.default().finishTransaction(transaction)

        // Call completion
        purchaseCompletion?(.success(transaction))
        purchaseCompletion = nil
    }

    private func handleFailed(_ transaction: SKPaymentTransaction) {
        if let error = transaction.error as? SKError {
            if error.code != .paymentCancelled {
                print("Purchase failed: \(error.localizedDescription)")
                purchaseCompletion?(.failure(error))
            } else {
                purchaseCompletion?(.failure(StoreKitError.cancelled))
            }
        }

        SKPaymentQueue.default().finishTransaction(transaction)
        purchaseCompletion = nil
    }

    private func handleRestored(_ transaction: SKPaymentTransaction) {
        subscriptionStatus = .active
        sendReceiptToBackend(transaction: transaction)
        SKPaymentQueue.default().finishTransaction(transaction)
    }

    private func sendReceiptToBackend(transaction: SKPaymentTransaction) {
        guard let receiptURL = Bundle.main.appStoreReceiptURL,
              let receiptData = try? Data(contentsOf: receiptURL) else {
            return
        }

        let receiptString = receiptData.base64EncodedString()

        // Send to backend
        Task {
            let apiService = APIService()
            do {
                let _: ReceiptValidationResponse = try await apiService.performAuthRequest(
                    path: "/subscription/validate-receipt",
                    method: "POST",
                    body: [
                        "receiptData": receiptString,
                        "transactionId": transaction.transactionIdentifier ?? ""
                    ]
                )
                print("Receipt validated successfully")
            } catch {
                print("Failed to validate receipt: \(error)")
            }
        }
    }
}

// MARK: - Models

struct ReceiptValidationResponse: Codable {
    let success: Bool
    let data: ReceiptData?
}

struct ReceiptData: Codable {
    let subscription: SubscriptionInfo
}

struct SubscriptionInfo: Codable {
    let status: String
    let renewalDate: String?
}

enum StoreKitError: Error, LocalizedError {
    case cannotMakePurchase
    case cancelled
    case productNotFound

    var errorDescription: String? {
        switch self {
        case .cannotMakePurchase:
            return "In-app purchases are not available"
        case .cancelled:
            return "Purchase was cancelled"
        case .productNotFound:
            return "Product not found"
        }
    }
}
