//
//  TodayView.swift
//  ScreenTimeBudget
//
//  Main dashboard showing today's usage
//

import SwiftUI

struct TodayView: View {
    @StateObject private var viewModel = TodayViewModel()

    var body: some View {
        NavigationView {
            ZStack {
                // Dark background
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Hero Summary Card
                        summaryCard
                            .padding(.top, 20)

                        // Category Breakdown
                        categorySection

                        // Monthly Chart
                        monthlySection
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Today")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(Color.black, for: .navigationBar)
            .refreshable {
                await viewModel.refresh()
            }
            .task {
                await viewModel.loadData()
            }
        }
    }

    // MARK: - Summary Card

    private var summaryCard: some View {
        VStack(spacing: 24) {
            Text("TODAY'S SCREEN TIME")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white.opacity(0.7))
                .tracking(2.0)

            // Time display - large and bold
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(viewModel.timeUsedFormatted)
                    .font(.system(size: 68, weight: .bold))
                    .foregroundColor(.white)

                VStack(alignment: .leading, spacing: 4) {
                    Text("/")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundColor(.white.opacity(0.4))
                    Text(viewModel.dailyBudgetFormatted)
                        .font(.system(size: 28, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                }
                .offset(y: -4)
            }

            // Progress bar - thicker and more prominent
            VStack(spacing: 8) {
                ProgressBar(value: viewModel.progress, color: viewModel.statusColor, height: 12)
                    .frame(height: 12)
                    .padding(.horizontal, 20)

                HStack {
                    Text("0h")
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.4))
                    Spacer()
                    Text(viewModel.dailyBudgetFormatted)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.4))
                }
                .padding(.horizontal, 20)
            }

            // Remaining time
            Text(viewModel.remainingText)
                .font(.system(size: 19, weight: .semibold))
                .foregroundColor(viewModel.statusColor)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    Capsule()
                        .fill(viewModel.statusColor.opacity(0.15))
                )
        }
        .padding(.vertical, 44)
        .padding(.horizontal, 28)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.38, green: 0.38, blue: 0.39),
                            Color(red: 0.28, green: 0.28, blue: 0.29)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(
                            LinearGradient(
                                colors: [Color.white.opacity(0.2), Color.white.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: .black.opacity(0.4), radius: 25, x: 0, y: 12)
        )
    }

    // MARK: - Category Section

    private var categorySection: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("TODAY BY CATEGORY")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.white.opacity(0.9))
                .tracking(1.5)
                .padding(.horizontal, 4)

            if viewModel.categories.isEmpty {
                // Empty state
                VStack(spacing: 12) {
                    Image(systemName: "square.grid.2x2")
                        .font(.system(size: 48))
                        .foregroundColor(.white.opacity(0.3))

                    Text("No budget set")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.6))

                    NavigationLink("Set up your budget") {
                        BudgetView()
                    }
                    .buttonStyle(.bordered)
                    .tint(.blue)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                VStack(spacing: 0) {
                    ForEach(viewModel.categories) { category in
                        CategoryRow(
                            icon: category.icon,
                            name: category.name,
                            minutesUsed: category.minutesUsed,
                            dailyBudgetMinutes: category.dailyBudget,
                            isUnlimited: category.isUnlimited
                        )
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)

                        if category.id != viewModel.categories.last?.id {
                            Divider()
                                .background(Color.white.opacity(0.1))
                        }
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(red: 0.15, green: 0.15, blue: 0.16))
                        .shadow(color: .black.opacity(0.2), radius: 15, x: 0, y: 5)
                )
            }
        }
    }

    // MARK: - Monthly Section

    private var monthlySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            MonthlyChart(
                dataPoints: viewModel.monthlyData,
                currentDay: viewModel.currentDay
            )

            // Monthly stats
            if !viewModel.monthlyData.isEmpty {
                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Budget")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.5))
                        Text(viewModel.monthlyBudgetFormatted)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Used")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.5))
                        Text(viewModel.monthlyUsedFormatted)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Avg/day")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.5))
                        Text(viewModel.avgPerDayFormatted)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.05))
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(red: 0.15, green: 0.15, blue: 0.16))
                .shadow(color: .black.opacity(0.2), radius: 15, x: 0, y: 5)
        )
    }
}

// MARK: - ViewModel

@MainActor
class TodayViewModel: ObservableObject {
    @Published var categories: [CategoryViewModel] = []
    @Published var monthlyData: [DailyUsagePoint] = []
    @Published var totalMinutesUsed: Int = 0
    @Published var totalDailyBudget: Int = 0
    @Published var isLoading = false

    private let apiService = APIService()

    var progress: Double {
        guard totalDailyBudget > 0 else { return 0 }
        return min(1.0, Double(totalMinutesUsed) / Double(totalDailyBudget))
    }

    var statusColor: Color {
        if progress >= 1.0 {
            return .red
        } else if progress >= 0.8 {
            return .orange
        } else {
            return .green
        }
    }

    var timeUsedFormatted: String {
        TimeFormatter.formatMinutes(totalMinutesUsed)
    }

    var dailyBudgetFormatted: String {
        TimeFormatter.formatMinutes(totalDailyBudget)
    }

    var remainingText: String {
        let remaining = max(0, totalDailyBudget - totalMinutesUsed)
        if remaining > 0 {
            return "\(TimeFormatter.formatMinutes(remaining)) remaining"
        } else {
            let over = totalMinutesUsed - totalDailyBudget
            return "\(TimeFormatter.formatMinutes(over)) over budget"
        }
    }

    var currentDay: Int {
        Calendar.current.component(.day, from: Date())
    }

    var monthlyBudgetFormatted: String {
        let total = categories.reduce(0) { $0 + ($1.isUnlimited ? 0 : $1.dailyBudget) }
        let daysInMonth = Calendar.current.range(of: .day, in: .month, for: Date())?.count ?? 30
        return TimeFormatter.formatMinutes(total * daysInMonth)
    }

    var monthlyUsedFormatted: String {
        let total = monthlyData.reduce(0) { $0 + $1.minutes }
        return TimeFormatter.formatMinutes(total)
    }

    var avgPerDayFormatted: String {
        guard !monthlyData.isEmpty else { return "0m" }
        let total = monthlyData.reduce(0) { $0 + $1.minutes }
        let avg = total / monthlyData.count
        return TimeFormatter.formatMinutes(avg)
    }

    func loadData() async {
        isLoading = true
        defer { isLoading = false }

        // Load mock data for now
        loadMockData()

        // TODO: Uncomment when backend is ready
        /*
        do {
            let userId = UserManager.shared.userId
            let budgetStatus = try await apiService.getDailyUsage(userId: userId, date: Date())

            // Process budget status into categories
            var cats: [CategoryViewModel] = []
            for (categoryType, status) in budgetStatus.categories {
                cats.append(CategoryViewModel(
                    categoryType: categoryType,
                    minutesUsed: status.totalMinutes,
                    dailyBudget: status.dailyBudget,
                    isUnlimited: status.dailyBudget == 0
                ))
            }

            categories = cats.sorted { $0.minutesUsed > $1.minutesUsed }
            totalMinutesUsed = budgetStatus.totalMinutes
            totalDailyBudget = cats.reduce(0) { $0 + $1.dailyBudget }

        } catch {
            print("Error loading data: \(error)")
        }
        */
    }

    func refresh() async {
        await loadData()
    }

    private func loadMockData() {
        categories = [
            CategoryViewModel(categoryType: "social_media", minutesUsed: 80, dailyBudget: 90, isUnlimited: false),
            CategoryViewModel(categoryType: "entertainment", minutesUsed: 45, dailyBudget: 90, isUnlimited: false),
            CategoryViewModel(categoryType: "gaming", minutesUsed: 10, dailyBudget: 40, isUnlimited: false),
            CategoryViewModel(categoryType: "productivity", minutesUsed: 120, dailyBudget: 0, isUnlimited: true),
        ]

        totalMinutesUsed = 135
        totalDailyBudget = 220

        monthlyData = [
            DailyUsagePoint(day: 1, minutes: 180, budgetMinutes: 220),
            DailyUsagePoint(day: 2, minutes: 210, budgetMinutes: 220),
            DailyUsagePoint(day: 3, minutes: 150, budgetMinutes: 220),
            DailyUsagePoint(day: 4, minutes: 135, budgetMinutes: 220),
        ]
    }
}

struct CategoryViewModel: Identifiable {
    let id = UUID()
    let categoryType: String
    let minutesUsed: Int
    let dailyBudget: Int
    let isUnlimited: Bool

    var name: String {
        switch categoryType {
        case "social_media": return "Social Media"
        case "entertainment": return "Entertainment"
        case "gaming": return "Gaming"
        case "productivity": return "Productivity"
        case "shopping": return "Shopping"
        case "news_reading": return "News & Reading"
        case "health_fitness": return "Health & Fitness"
        default: return "Other"
        }
    }

    var icon: String {
        switch categoryType {
        case "social_media": return "📱"
        case "entertainment": return "🎬"
        case "gaming": return "🎮"
        case "productivity": return "💼"
        case "shopping": return "🛍️"
        case "news_reading": return "📰"
        case "health_fitness": return "❤️"
        default: return "📦"
        }
    }
}

#Preview {
    TodayView()
}
