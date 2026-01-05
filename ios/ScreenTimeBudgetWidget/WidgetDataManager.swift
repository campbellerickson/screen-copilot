//
//  WidgetDataManager.swift
//  ScreenTimeBudgetWidget
//
//  Manages data sharing between app and widget via App Groups
//

import Foundation

class WidgetDataManager {
    static let shared = WidgetDataManager()

    private let appGroupIdentifier = Constants.appGroupIdentifier
    private let widgetDataKey = "widget_data"

    private init() {}

    /// Save widget data to shared container
    func saveWidgetData(_ data: WidgetData) {
        guard let container = UserDefaults(suiteName: appGroupIdentifier) else {
            print("⚠️ Failed to access App Group container")
            return
        }

        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(data) {
            container.set(encoded, forKey: widgetDataKey)
            container.synchronize()
            print("✅ Widget data saved: \(data.totalMinutesUsedToday) min used today")
        }
    }

    /// Load widget data from shared container
    func loadWidgetData() -> WidgetData? {
        guard let container = UserDefaults(suiteName: appGroupIdentifier) else {
            print("⚠️ Failed to access App Group container")
            return nil
        }

        guard let data = container.data(forKey: widgetDataKey) else {
            print("⚠️ No widget data found in container")
            return nil
        }

        let decoder = JSONDecoder()
        if let widgetData = try? decoder.decode(WidgetData.self, from: data) {
            print("✅ Widget data loaded: \(widgetData.totalMinutesUsedToday) min used today")
            return widgetData
        }

        return nil
    }

    /// Generate widget data from budget status response
    func generateWidgetData(from budgetStatus: BudgetStatusResponse, monthlyData: [DailyUsagePoint] = []) -> WidgetData {
        var totalUsedToday = budgetStatus.totalMinutes
        var totalBudgetToday = 0
        var topCategories: [CategoryUsage] = []

        // Calculate totals and top categories
        let sortedCategories = budgetStatus.categories.sorted { $0.value.totalMinutes > $1.value.totalMinutes }

        for (categoryType, status) in sortedCategories {
            totalBudgetToday += status.dailyBudget

            // Add to top 3 categories
            if topCategories.count < 3 {
                let color = categoryColorForType(categoryType)
                topCategories.append(
                    CategoryUsage(
                        categoryName: categoryDisplayName(categoryType),
                        minutes: status.totalMinutes,
                        color: color
                    )
                )
            }
        }

        return WidgetData(
            lastUpdated: Date(),
            totalMinutesUsedToday: totalUsedToday,
            totalDailyBudgetMinutes: totalBudgetToday,
            monthlyData: monthlyData,
            topCategories: topCategories
        )
    }

    // MARK: - Helpers

    private func categoryDisplayName(_ type: String) -> String {
        switch type {
        case "social_media": return "Social Media"
        case "entertainment": return "Entertainment"
        case "gaming": return "Gaming"
        case "productivity": return "Productivity"
        case "shopping": return "Shopping"
        case "news_reading": return "News"
        case "health_fitness": return "Health"
        default: return "Other"
        }
    }

    private func categoryColorForType(_ type: String) -> String {
        switch type {
        case "social_media": return "blue"
        case "entertainment": return "purple"
        case "gaming": return "red"
        case "productivity": return "gray"
        case "shopping": return "green"
        case "news_reading": return "orange"
        case "health_fitness": return "pink"
        default: return "gray"
        }
    }
}
