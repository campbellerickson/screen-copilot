//
//  MoreView.swift
//  ScreenTimeBudget
//
//  Settings and account management screen
//

import SwiftUI

struct MoreView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var viewModel = MoreViewModel()
    @State private var showingDeleteAccountAlert = false
    @State private var showingDeleteConfirmation = false
    @State private var deleteAccountText = ""

    var body: some View {
        NavigationView {
            ZStack {
                // Deep blue background
                Color(red: 0.05, green: 0.1, blue: 0.15).ignoresSafeArea()

                List {
                    // Account Section
                    Section {
                        HStack(spacing: 12) {
                            // Profile icon
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.blue, Color.purple],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 50, height: 50)

                                Text((authManager.currentUser?.name?.prefix(1) ?? authManager.currentUser?.email.prefix(1) ?? "U").uppercased())
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text(authManager.currentUser?.name ?? "User")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(.white)

                                Text(authManager.currentUser?.email ?? "")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.7))
                            }

                            Spacer()
                        }
                        .padding(.vertical, 4)

                        Button(action: {
                            Task {
                                await viewModel.loadSubscriptionStatus()
                            }
                        }) {
                            HStack {
                                Label("Refresh Subscription", systemImage: "arrow.clockwise")
                                if viewModel.isLoadingSubscription {
                                    Spacer()
                                    ProgressView()
                                        .scaleEffect(0.8)
                                }
                            }
                        }
                        .disabled(viewModel.isLoadingSubscription)
                    } header: {
                        Text("Account")
                    }

                    // Subscription Section
                    if viewModel.subscriptionStatus != nil {
                        Section {
                            SubscriptionStatusCard(status: viewModel.subscriptionStatus!)

                            if viewModel.subscriptionStatus?.status == "active" || viewModel.subscriptionStatus?.status == "trial" {
                                Button(role: .destructive, action: {
                                    Task {
                                        await viewModel.cancelSubscription()
                                    }
                                }) {
                                    Label("Cancel Subscription", systemImage: "xmark.circle")
                                }
                                .disabled(viewModel.isCancelling)
                            }
                        } header: {
                            Text("Subscription")
                        } footer: {
                            if viewModel.subscriptionStatus?.status == "trial" {
                                Text("Your free trial will convert to a paid subscription unless cancelled.")
                            } else if viewModel.subscriptionStatus?.status == "active" {
                                Text("Manage your subscription through the App Store or cancel it here.")
                            }
                        }
                    }

                    // Notifications Section
                    Section {
                        Toggle(isOn: $viewModel.notificationsEnabled) {
                            Label("Budget Alerts", systemImage: "bell.fill")
                        }

                        NavigationLink {
                            Text("Notification settings coming soon")
                                .navigationTitle("Notifications")
                        } label: {
                            Label("Notification Settings", systemImage: "bell.badge")
                        }
                    } header: {
                        Text("Notifications")
                    }

                    // Data Section
                    Section {
                        Button(action: {
                            // Sync data
                        }) {
                            Label("Sync Now", systemImage: "arrow.triangle.2.circlepath")
                        }

                        NavigationLink {
                            Text("Data management coming soon")
                                .navigationTitle("Data & Privacy")
                        } label: {
                            Label("Data & Privacy", systemImage: "lock.shield")
                        }
                    } header: {
                        Text("Data")
                    }

                    // About Section
                    Section {
                        HStack {
                            Text("Version")
                            Spacer()
                            Text("1.0.0")
                                .foregroundColor(.secondary)
                        }

                        NavigationLink {
                            AboutView()
                        } label: {
                            Label("About", systemImage: "info.circle")
                        }

                        Link(destination: URL(string: "https://example.com/support")!) {
                            Label("Support", systemImage: "questionmark.circle")
                        }

                        Link(destination: URL(string: "https://example.com/privacy")!) {
                            Label("Privacy Policy", systemImage: "hand.raised")
                        }
                    } header: {
                        Text("About")
                    }

                    // Account Actions Section
                    Section {
                        Button(action: {
                            showingDeleteAccountAlert = true
                        }) {
                            Label("Delete Account", systemImage: "trash")
                                .foregroundColor(.red)
                        }
                    } header: {
                        Text("Danger Zone")
                    } footer: {
                        Text("Deleting your account will cancel your subscription and permanently delete all your data. This action cannot be undone.")
                    }
                }
                .scrollContentBackground(.hidden)
                .background(Color.clear)
            }
            .navigationTitle("Settings")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color(red: 0.05, green: 0.1, blue: 0.15), for: .navigationBar)
            .task {
                await viewModel.loadSubscriptionStatus()
            }
            .alert("Delete Account", isPresented: $showingDeleteAccountAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Continue", role: .destructive) {
                    showingDeleteConfirmation = true
                }
            } message: {
                Text("This will permanently delete your account and all data. Are you sure you want to continue?")
            }
            .alert("Confirm Deletion", isPresented: $showingDeleteConfirmation) {
                TextField("Type DELETE to confirm", text: $deleteAccountText)
                Button("Cancel", role: .cancel) {
                    deleteAccountText = ""
                }
                Button("Delete Account", role: .destructive) {
                    if deleteAccountText == "DELETE" {
                        Task {
                            await viewModel.deleteAccount()
                            if viewModel.accountDeleted {
                                authManager.logout()
                            }
                        }
                    }
                    deleteAccountText = ""
                }
            } message: {
                Text("Type 'DELETE' in the field above to confirm account deletion. This action cannot be undone.")
            }
            .alert("Account Deleted", isPresented: $viewModel.showAccountDeletedAlert) {
                Button("OK") {
                    authManager.logout()
                }
            } message: {
                Text("Your account has been successfully deleted.")
            }
            .alert("Error", isPresented: $viewModel.showErrorAlert) {
                Button("OK") { }
            } message: {
                Text(viewModel.errorMessage ?? "An error occurred")
            }
        }
    }
}

// MARK: - Subscription Status Card

struct SubscriptionStatusCard: View {
    let status: SubscriptionStatusResponse

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: statusIcon)
                    .font(.system(size: 24))
                    .foregroundColor(statusColor)
                    .frame(width: 44, height: 44)
                    .background(
                        Circle()
                            .fill(statusColor.opacity(0.2))
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(statusTitle)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)

                    Text(status.message)
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                }

                Spacer()
            }

            if let trialEndDate = status.trialEndDate, status.status == "trial" {
                Divider()
                    .background(Color.white.opacity(0.1))

                HStack {
                    Text("Trial Ends")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                    Spacer()
                    Text(formatDate(trialEndDate))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                }
            }

            if let renewalDate = status.renewalDate, status.status == "active" {
                Divider()
                    .background(Color.white.opacity(0.1))

                HStack {
                    Text("Next Renewal")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                    Spacer()
                    Text(formatDate(renewalDate))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                }
            }

            if let price = status.priceUSD {
                Divider()
                    .background(Color.white.opacity(0.1))

                HStack {
                    Text("Price")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                    Spacer()
                    Text("$\(String(format: "%.2f", price))/month")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(red: 0.1, green: 0.15, blue: 0.2))
        )
    }

    private var statusIcon: String {
        switch status.status {
        case "trial": return "gift.fill"
        case "active": return "checkmark.circle.fill"
        case "cancelled": return "xmark.circle.fill"
        default: return "questionmark.circle.fill"
        }
    }

    private var statusColor: Color {
        switch status.status {
        case "trial": return .green
        case "active": return .blue
        case "cancelled": return .orange
        default: return .gray
        }
    }

    private var statusTitle: String {
        switch status.status {
        case "trial": return "Free Trial"
        case "active": return "Active Subscription"
        case "cancelled": return "Cancelled"
        default: return "No Subscription"
        }
    }

    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate, .withTime, .withDashSeparatorInDate, .withColonSeparatorInTime]
        
        if let date = formatter.date(from: dateString) {
            let displayFormatter = DateFormatter()
            displayFormatter.dateStyle = .medium
            displayFormatter.timeStyle = .none
            return displayFormatter.string(from: date)
        }
        return dateString
    }
}

// MARK: - ViewModel

@MainActor
class MoreViewModel: ObservableObject {
    @Published var subscriptionStatus: SubscriptionStatusResponse?
    @Published var notificationsEnabled = true
    @Published var isLoadingSubscription = false
    @Published var isCancelling = false
    @Published var isDeleting = false
    @Published var showAccountDeletedAlert = false
    @Published var showErrorAlert = false
    @Published var errorMessage: String?
    @Published var accountDeleted = false

    private let apiService = APIService()

    func loadSubscriptionStatus() async {
        isLoadingSubscription = true
        defer { isLoadingSubscription = false }

        do {
            subscriptionStatus = try await apiService.getSubscriptionStatus()
        } catch {
            errorMessage = "Failed to load subscription status: \(error.localizedDescription)"
            showErrorAlert = true
        }
    }

    func cancelSubscription() async {
        isCancelling = true
        defer { isCancelling = false }

        do {
            try await apiService.cancelSubscription()
            // Reload subscription status
            await loadSubscriptionStatus()
        } catch {
            errorMessage = "Failed to cancel subscription: \(error.localizedDescription)"
            showErrorAlert = true
        }
    }

    func deleteAccount() async {
        isDeleting = true
        defer { isDeleting = false }

        do {
            try await apiService.deleteAccount()
            accountDeleted = true
            showAccountDeletedAlert = true
        } catch {
            errorMessage = "Failed to delete account: \(error.localizedDescription)"
            showErrorAlert = true
        }
    }
}

// MARK: - About View

struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // App icon
                Image(systemName: "hourglass.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                    .padding(.top, 40)

                VStack(spacing: 8) {
                    Text("Screen Time Copilot")
                        .font(.system(size: 28, weight: .bold))

                    Text("Version 1.0.0")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                }

                Text("Take control of your screen time by setting monthly budgets for app categories, just like managing your finances.")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                VStack(spacing: 16) {
                    featureRow(icon: "chart.bar.fill", title: "Track Usage", description: "Monitor daily and monthly screen time")
                    featureRow(icon: "slider.horizontal.3", title: "Set Budgets", description: "Define monthly limits per category")
                    featureRow(icon: "bell.fill", title: "Get Alerts", description: "Notifications when exceeding limits")
                }
                .padding()

                Text("© 2026 Screen Time Copilot. All rights reserved.")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .padding(.bottom, 40)
            }
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func featureRow(icon: String, title: String, description: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(.blue)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(Color.blue.opacity(0.1))
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))

                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
    }
}

#Preview {
    MoreView()
        .environmentObject(AuthManager.shared)
}

#Preview("About") {
    NavigationView {
        AboutView()
    }
}
