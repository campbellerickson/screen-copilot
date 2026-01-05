//
//  SubscriptionPaywallView.swift
//  ScreenTimeBudget
//
//  Subscription paywall screen
//

import SwiftUI
import StoreKit

struct SubscriptionPaywallView: View {
    @StateObject private var viewModel = SubscriptionPaywallViewModel()
    @StateObject private var storeKit = StoreKitManager.shared
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            // Dark background gradient
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.05, blue: 0.15),
                    Color.black
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 16) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 64))
                            .foregroundColor(.yellow)
                            .padding(.top, 60)

                        Text("Screen Budget Pro")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)

                        Text("Take control of your digital wellbeing")
                            .font(.system(size: 17))
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                    }

                    // Features
                    VStack(spacing: 20) {
                        FeatureRow(
                            icon: "chart.bar.fill",
                            title: "Daily Usage Tracking",
                            description: "Monitor your screen time across all categories"
                        )

                        FeatureRow(
                            icon: "slider.horizontal.3",
                            title: "Custom Budgets",
                            description: "Set personalized limits for each app category"
                        )

                        FeatureRow(
                            icon: "bell.fill",
                            title: "Smart Alerts",
                            description: "Get notified when you're close to your limits"
                        )

                        FeatureRow(
                            icon: "chart.line.uptrend.xyaxis",
                            title: "Insights & Trends",
                            description: "Understand your usage patterns over time"
                        )
                    }
                    .padding(.horizontal, 32)

                    // Pricing card
                    VStack(spacing: 20) {
                        // Trial badge
                        HStack {
                            Spacer()
                            Text("7-DAY FREE TRIAL")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule()
                                        .fill(Color.green)
                                )
                            Spacer()
                        }

                        // Price
                        VStack(spacing: 8) {
                            HStack(alignment: .firstTextBaseline, spacing: 4) {
                                Text("$0.99")
                                    .font(.system(size: 48, weight: .bold))
                                    .foregroundColor(.white)
                                Text("/month")
                                    .font(.system(size: 18))
                                    .foregroundColor(.white.opacity(0.6))
                            }

                            Text("Cancel anytime")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.6))
                        }

                        // Trial info
                        VStack(spacing: 12) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("First 7 days completely free")
                                    .font(.system(size: 15))
                                Spacer()
                            }

                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("$0.99/month after trial ends")
                                    .font(.system(size: 15))
                                Spacer()
                            }

                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                Text("No commitment, cancel anytime")
                                    .font(.system(size: 15))
                                Spacer()
                            }
                        }
                        .foregroundColor(.white.opacity(0.9))
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white.opacity(0.05))
                        )
                    }
                    .padding(24)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.blue.opacity(0.2),
                                        Color.purple.opacity(0.2)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 24)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            )
                    )
                    .padding(.horizontal, 24)

                    // Subscribe button
                    Button(action: {
                        Task {
                            await viewModel.subscribe()
                        }
                    }) {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("Start Free Trial")
                                    .font(.system(size: 18, weight: .bold))
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 60)
                        .background(
                            LinearGradient(
                                colors: [Color.blue, Color.purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(16)
                    }
                    .disabled(viewModel.isLoading)
                    .padding(.horizontal, 24)

                    // Restore purchases
                    Button(action: {
                        Task {
                            await viewModel.restorePurchases()
                        }
                    }) {
                        Text("Restore Purchases")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    }

                    // Error message
                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(.system(size: 14))
                            .foregroundColor(.red)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }

                    // Terms
                    VStack(spacing: 8) {
                        Text("By subscribing, you agree to our")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.5))

                        HStack(spacing: 4) {
                            Button("Terms of Service") {
                                // TODO: Show terms
                            }
                            .font(.system(size: 12))
                            .foregroundColor(.blue.opacity(0.8))

                            Text("and")
                                .font(.system(size: 12))
                                .foregroundColor(.white.opacity(0.5))

                            Button("Privacy Policy") {
                                // TODO: Show privacy policy
                            }
                            .font(.system(size: 12))
                            .foregroundColor(.blue.opacity(0.8))
                        }
                    }
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 40)
                }
            }
        }
        .onChange(of: viewModel.subscriptionSuccess) { success in
            if success {
                dismiss()
            }
        }
    }
}

// MARK: - Feature Row

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.blue)
                .frame(width: 40, height: 40)
                .background(
                    Circle()
                        .fill(Color.blue.opacity(0.15))
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)

                Text(description)
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.7))
            }

            Spacer()
        }
    }
}

// MARK: - ViewModel

@MainActor
class SubscriptionPaywallViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var subscriptionSuccess = false

    private let storeKit = StoreKitManager.shared

    func subscribe() async {
        isLoading = true
        errorMessage = nil

        do {
            // Get the monthly subscription product
            guard let product = storeKit.products.first else {
                throw StoreKitError.productNotFound
            }

            // Purchase the product
            let transaction = try await storeKit.purchase(product: product)

            // Success!
            subscriptionSuccess = true

        } catch {
            if case StoreKitError.cancelled = error {
                // User cancelled - don't show error
            } else {
                errorMessage = error.localizedDescription
            }
        }

        isLoading = false
    }

    func restorePurchases() async {
        isLoading = true
        errorMessage = nil

        storeKit.restorePurchases()

        // Wait a moment for restoration to complete
        try? await Task.sleep(nanoseconds: 2_000_000_000)

        await storeKit.checkSubscriptionStatus()

        if storeKit.subscriptionStatus == .active {
            subscriptionSuccess = true
        } else {
            errorMessage = "No purchases found to restore"
        }

        isLoading = false
    }
}

#Preview {
    SubscriptionPaywallView()
}
