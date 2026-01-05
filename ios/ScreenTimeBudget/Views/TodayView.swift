//
//  TodayView.swift
//  ScreenTimeBudget
//
//  Main dashboard showing today's usage - Modern Copilot-style design
//

import SwiftUI

struct TodayView: View {
    @StateObject private var viewModel = TodayViewModel()
    
    var body: some View {
        ZStack {
            // Deep blue background matching Copilot
            Color(red: 0.05, green: 0.1, blue: 0.15).ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 0) {
                    // Header with app name, settings, and message icons
                    headerView
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                        .padding(.bottom, 16)
                    
                    // Horizontal scrollable tabs (optional for future use)
                    // For now, we'll just show the main content
                    
                    // Summary Card - Large and prominent
                    summaryCard
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)
                    
                    // Streak Badge
                    StreakBadge(currentStreak: viewModel.currentStreak, longestStreak: viewModel.longestStreak)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 32)
                    
                    // TO REVIEW Section
                    toReviewSection
                        .padding(.horizontal, 20)
                        .padding(.bottom, 32)
                    
                    // BUDGETS Section with horizontal scrolling
                    budgetsSection
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                }
            }
        }
        .refreshable {
            await viewModel.refresh()
        }
        .task {
            await viewModel.loadData()
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack {
            // Settings icon
            Button(action: {
                // Navigate to settings
            }) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer()
            
            // App name - large and bold
            Text("Screen Budget")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(.white)
            
            Spacer()
            
            // Message/Support icon
            Button(action: {
                // Show support/messages
            }) {
                Image(systemName: "message.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
            }
        }
    }
    
    // MARK: - Summary Card
    
    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Main metric - large and bold
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(viewModel.timeRemainingFormatted)
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    // Info icon (optional)
                    Button(action: {}) {
                        Image(systemName: "questionmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.white.opacity(0.4))
                    }
                }
                
                // Subtitle
                Text("out of \(viewModel.dailyBudgetFormatted) budgeted")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            // Gradient line chart
            gradientChart
            
            // Status pill
            HStack {
                Spacer()
                
                Text(viewModel.statusPillText)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(viewModel.statusPillColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(viewModel.statusPillColor.opacity(0.2))
                    )
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.1, green: 0.15, blue: 0.25),
                            Color(red: 0.08, green: 0.12, blue: 0.2)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
        )
    }
    
    // MARK: - Gradient Chart
    
    private var gradientChart: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background line
                Path { path in
                    let points = viewModel.chartDataPoints(width: geometry.size.width, height: geometry.size.height)
                    path.move(to: points[0])
                    for i in 1..<points.count {
                        path.addLine(to: points[i])
                    }
                }
                .stroke(Color.white.opacity(0.2), style: StrokeStyle(lineWidth: 2, lineCap: .round))
                
                // Gradient line
                Path { path in
                    let points = viewModel.chartDataPoints(width: geometry.size.width, height: geometry.size.height)
                    path.move(to: points[0])
                    for i in 1..<points.count {
                        path.addLine(to: points[i])
                    }
                }
                .stroke(
                    LinearGradient(
                        colors: [Color.yellow, Color.green],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
                
                // End point circle
                if let lastPoint = viewModel.chartDataPoints(width: geometry.size.width, height: geometry.size.height).last {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 8, height: 8)
                        .position(lastPoint)
                }
            }
        }
        .frame(height: 60)
    }
    
    // MARK: - TO REVIEW Section
    
    private var toReviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("TO REVIEW")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color(red: 0.4, green: 0.6, blue: 1.0))
                    .tracking(1.2)
                
                Spacer()
                
                Button("View all >") {
                    // Navigate to full review list
                }
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color(red: 0.4, green: 0.6, blue: 1.0))
            }
            
            if viewModel.recentApps.isEmpty {
                Text("No apps to review")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.5))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 16)
            } else {
                VStack(spacing: 0) {
                    ForEach(viewModel.recentApps) { app in
                        AppReviewRow(app: app)
                            .padding(.vertical, 12)
                        
                        if app.id != viewModel.recentApps.last?.id {
                            Divider()
                                .background(Color.white.opacity(0.1))
                                .padding(.leading, 56)
                        }
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(red: 0.1, green: 0.15, blue: 0.2))
                )
                
                // MARK AS REVIEWED button
                Button(action: {
                    // Mark all as reviewed
                }) {
                    Text("MARK AS REVIEWED")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(red: 0.1, green: 0.15, blue: 0.25))
                        )
                }
                .padding(.top, 12)
            }
        }
    }
    
    // MARK: - BUDGETS Section
    
    private var budgetsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("BUDGETS")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(Color(red: 0.4, green: 0.6, blue: 1.0))
                    .tracking(1.2)
                
                Spacer()
                
                Button("Categories >") {
                    // Navigate to categories
                }
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color(red: 0.4, green: 0.6, blue: 1.0))
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(viewModel.categoryBudgets) { budget in
                        CircularBudgetIndicator(budget: budget)
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }
}

// MARK: - App Review Row

struct AppReviewRow: View {
    let app: AppReviewItem
    
    var body: some View {
        HStack(spacing: 12) {
            // App icon/emoji
            Text(app.icon)
                .font(.system(size: 24))
                .frame(width: 44, height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white.opacity(0.1))
                )
            
            // App name
            Text(app.name)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white)
            
            Spacer()
            
            // Category tag
            HStack(spacing: 4) {
                if let categoryIcon = app.categoryIcon {
                    Text(categoryIcon)
                        .font(.system(size: 10))
                }
                Text(app.category)
                    .font(.system(size: 11, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(app.categoryColor.opacity(0.8))
            )
            
            // Time used
            Text(app.timeFormatted)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
                .frame(minWidth: 50, alignment: .trailing)
        }
        .padding(.horizontal, 16)
    }
}

// MARK: - Circular Budget Indicator

struct CircularBudgetIndicator: View {
    let budget: CategoryBudgetIndicator
    
    var body: some View {
        VStack(spacing: 8) {
            // Circular indicator with emoji
            ZStack {
                Circle()
                    .fill(budget.backgroundColor)
                    .frame(width: 64, height: 64)
                
                Text(budget.icon)
                    .font(.system(size: 32))
            }
            
            // Status text
            Text(budget.statusText)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(budget.textColor)
                .multilineTextAlignment(.center)
        }
        .frame(width: 80)
    }
}

// MARK: - ViewModel

@MainActor
class TodayViewModel: ObservableObject {
    @Published var categories: [CategoryViewModel] = []
    @Published var monthlyData: [DailyUsagePoint] = []
    @Published var totalMinutesUsed: Int = 0
    @Published var totalDailyBudget: Int = 0
    @Published var recentApps: [AppReviewItem] = []
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
    
    var timeRemainingFormatted: String {
        let remaining = max(0, totalDailyBudget - totalMinutesUsed)
        return TimeFormatter.formatMinutes(remaining) + " left"
    }
    
    var statusPillText: String {
        let remaining = totalDailyBudget - totalMinutesUsed
        if remaining > 0 {
            return "\(TimeFormatter.formatMinutes(remaining)) under"
        } else {
            let over = totalMinutesUsed - totalDailyBudget
            return "\(TimeFormatter.formatMinutes(over)) over"
        }
    }
    
    var statusPillColor: Color {
        let remaining = totalDailyBudget - totalMinutesUsed
        if remaining > 0 {
            return .green
        } else {
            return .red
        }
    }
    
    var categoryBudgets: [CategoryBudgetIndicator] {
        categories.map { category in
            let remaining = category.dailyBudget - category.minutesUsed
            let progress = category.dailyBudget > 0 ? Double(category.minutesUsed) / Double(category.dailyBudget) : 0
            
            var backgroundColor: Color
            var textColor: Color
            var statusText: String
            
            if category.isUnlimited {
                backgroundColor = Color(red: 0.15, green: 0.15, blue: 0.2)
                textColor = .white.opacity(0.7)
                statusText = "Unlimited"
            } else if remaining < 0 {
                backgroundColor = Color(red: 0.25, green: 0.1, blue: 0.1)
                textColor = .red
                statusText = "\(TimeFormatter.formatMinutes(abs(remaining))) over"
            } else if progress > 0.7 {
                backgroundColor = Color(red: 0.25, green: 0.15, blue: 0.1)
                textColor = .orange
                statusText = "\(TimeFormatter.formatMinutes(remaining)) left"
            } else {
                backgroundColor = Color(red: 0.1, green: 0.2, blue: 0.15)
                textColor = .green
                statusText = "\(TimeFormatter.formatMinutes(remaining)) left"
            }
            
            return CategoryBudgetIndicator(
                id: category.id,
                icon: category.icon,
                statusText: statusText,
                backgroundColor: backgroundColor,
                textColor: textColor
            )
        }
    }
    
    func chartDataPoints(width: CGFloat, height: CGFloat) -> [CGPoint] {
        guard !monthlyData.isEmpty else {
            return [CGPoint(x: 0, y: height / 2), CGPoint(x: width, y: height / 2)]
        }
        
        let maxMinutes = monthlyData.map { $0.minutes }.max() ?? 1
        let minMinutes = monthlyData.map { $0.minutes }.min() ?? 0
        let range = max(maxMinutes - minMinutes, 1)
        
        let spacing = width / CGFloat(max(monthlyData.count - 1, 1))
        var points: [CGPoint] = []
        
        for (index, point) in monthlyData.enumerated() {
            let x = CGFloat(index) * spacing
            let normalized = CGFloat(point.minutes - minMinutes) / CGFloat(range)
            let y = height - (normalized * height * 0.8) - (height * 0.1)
            points.append(CGPoint(x: x, y: y))
        }
        
        return points
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
        
        // Mock streak data (will be loaded from backend)
        currentStreak = 7
        longestStreak = 12
        
        monthlyData = [
            DailyUsagePoint(day: 1, minutes: 180, budgetMinutes: 220),
            DailyUsagePoint(day: 2, minutes: 210, budgetMinutes: 220),
            DailyUsagePoint(day: 3, minutes: 150, budgetMinutes: 220),
            DailyUsagePoint(day: 4, minutes: 135, budgetMinutes: 220),
        ]
        
        // Mock recent apps for review
        recentApps = [
            AppReviewItem(
                name: "Instagram",
                icon: "📷",
                category: "SOCIAL MEDIA",
                categoryIcon: "📱",
                categoryColor: .orange,
                minutesUsed: 45
            ),
            AppReviewItem(
                name: "YouTube",
                icon: "▶️",
                category: "ENTERTAINMENT",
                categoryIcon: "🎬",
                categoryColor: .green,
                minutesUsed: 30
            ),
        ]
    }
}

// MARK: - Supporting Models

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

struct AppReviewItem: Identifiable {
    let id = UUID()
    let name: String
    let icon: String
    let category: String
    let categoryIcon: String?
    let categoryColor: Color
    let minutesUsed: Int
    
    var timeFormatted: String {
        TimeFormatter.formatMinutes(minutesUsed)
    }
}

struct CategoryBudgetIndicator: Identifiable {
    let id: UUID
    let icon: String
    let statusText: String
    let backgroundColor: Color
    let textColor: Color
    
    init(id: UUID = UUID(), icon: String, statusText: String, backgroundColor: Color, textColor: Color) {
        self.id = id
        self.icon = icon
        self.statusText = statusText
        self.backgroundColor = backgroundColor
        self.textColor = textColor
    }
}

#Preview {
    TodayView()
}
