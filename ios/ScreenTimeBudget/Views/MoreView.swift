//
//  MoreView.swift
//  ScreenTimeBudget
//
//  Settings and more options screen
//

import SwiftUI

struct MoreView: View {
    @State private var notificationsEnabled = true
    @State private var showingResetAlert = false

    var body: some View {
        NavigationView {
            List {
                // Settings Section
                Section {
                    Toggle(isOn: $notificationsEnabled) {
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

                    Button(role: .destructive, action: {
                        showingResetAlert = true
                    }) {
                        Label("Reset All Data", systemImage: "trash")
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

                // Account Section
                Section {
                    Button(action: {
                        // Share app
                    }) {
                        Label("Share App", systemImage: "square.and.arrow.up")
                    }

                    Button(action: {
                        // Rate app
                    }) {
                        Label("Rate on App Store", systemImage: "star")
                    }
                }
            }
            .navigationTitle("More")
            .alert("Reset All Data?", isPresented: $showingResetAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    resetAllData()
                }
            } message: {
                Text("This will delete all your budgets, usage history, and settings. This action cannot be undone.")
            }
        }
    }

    private func resetAllData() {
        UserManager.shared.resetUser()
        // TODO: Clear local data and notify backend
    }
}

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
                    Text("Screen Budget")
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

                Text("© 2026 Screen Budget. All rights reserved.")
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
}

#Preview("About") {
    NavigationView {
        AboutView()
    }
}
