//
//  RootView.swift
//  ScreenTimeBudget
//
//  Root view that manages app authentication and subscription flow
//

import SwiftUI

struct RootView: View {
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var storeKit = StoreKitManager.shared
    @State private var isCheckingSubscription = true
    @State private var hasActiveSubscription = false

    var body: some View {
        Group {
            if !authManager.isAuthenticated {
                // Show login if not authenticated
                LoginView()
                    .environmentObject(authManager)
            } else if isCheckingSubscription {
                // Show loading while checking subscription
                LoadingView()
            } else if !hasActiveSubscription {
                // Show paywall if no active subscription
                SubscriptionPaywallView()
            } else {
                // Show main app
                MainTabView()
                    .environmentObject(authManager)
            }
        }
        .task {
            if authManager.isAuthenticated {
                await checkSubscriptionStatus()
            }
        }
        .onChange(of: authManager.isAuthenticated) { oldValue, newValue in
            if newValue {
                Task {
                    await checkSubscriptionStatus()
                }
            }
        }
    }

    private func checkSubscriptionStatus() async {
        isCheckingSubscription = true

        // Check subscription status from backend
        let apiService = APIService()
        do {
            let response = try await apiService.getSubscriptionStatus()
            hasActiveSubscription = response.hasAccess
        } catch {
            print("Failed to check subscription status: \(error)")
            hasActiveSubscription = false
        }

        isCheckingSubscription = false
    }
}

// MARK: - Loading View

struct LoadingView: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 20) {
                Image(systemName: "hourglass")
                    .font(.system(size: 64))
                    .foregroundColor(.blue)

                ProgressView()
                    .tint(.blue)

                Text("Loading...")
                    .font(.system(size: 16))
                    .foregroundColor(.white.opacity(0.6))
            }
        }
    }
}

// MARK: - Models
// Note: SubscriptionStatusResponse is defined in APIService.swift

#Preview {
    RootView()
}
