//
//  WidgetModels.swift
//  ScreenTimeBudgetWidget
//
//  Data models for the widget
//

import Foundation

/// Shared data structure for the widget
struct WidgetData: Codable {
    let lastUpdated: Date
    let totalMinutesUsedToday: Int
    let totalDailyBudgetMinutes: Int
    let monthlyData: [DailyUsagePoint]
    let topCategories: [CategoryUsage]

    /// Minutes remaining today
    var minutesRemaining: Int {
        max(0, totalDailyBudgetMinutes - totalMinutesUsedToday)
    }

    /// Progress percentage (0.0 to 1.0)
    var progress: Double {
        guard totalDailyBudgetMinutes > 0 else { return 0 }
        return min(1.0, Double(totalMinutesUsedToday) / Double(totalDailyBudgetMinutes))
    }

    /// Status color based on usage
    var status: UsageWidgetStatus {
        let percentage = progress
        if percentage >= 1.0 {
            return .over
        } else if percentage >= 0.8 {
            return .warning
        } else {
            return .good
        }
    }

    /// Format minutes as "Xh Ym"
    static func formatMinutes(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60

        if hours > 0 && mins > 0 {
            return "\(hours)h \(mins)m"
        } else if hours > 0 {
            return "\(hours)h"
        } else {
            return "\(mins)m"
        }
    }
}

struct DailyUsagePoint: Codable, Identifiable {
    let id = UUID()
    let day: Int // Day of month (1-31)
    let minutes: Int
    let budgetMinutes: Int

    enum CodingKeys: String, CodingKey {
        case day, minutes, budgetMinutes
    }
}

struct CategoryUsage: Codable, Identifiable {
    let id = UUID()
    let categoryName: String
    let minutes: Int
    let color: String

    enum CodingKeys: String, CodingKey {
        case categoryName, minutes, color
    }
}

enum UsageWidgetStatus {
    case good
    case warning
    case over

    var colorName: String {
        switch self {
        case .good: return "green"
        case .warning: return "orange"
        case .over: return "red"
        }
    }
}

/// Sample data for previews and when real data unavailable
extension WidgetData {
    static var placeholder: WidgetData {
        WidgetData(
            lastUpdated: Date(),
            totalMinutesUsedToday: 120,
            totalDailyBudgetMinutes: 240,
            monthlyData: [
                DailyUsagePoint(day: 1, minutes: 180, budgetMinutes: 240),
                DailyUsagePoint(day: 2, minutes: 210, budgetMinutes: 240),
                DailyUsagePoint(day: 3, minutes: 150, budgetMinutes: 240),
                DailyUsagePoint(day: 4, minutes: 120, budgetMinutes: 240),
            ],
            topCategories: [
                CategoryUsage(categoryName: "Social Media", minutes: 60, color: "blue"),
                CategoryUsage(categoryName: "Entertainment", minutes: 45, color: "purple"),
                CategoryUsage(categoryName: "Gaming", minutes: 15, color: "red"),
            ]
        )
    }

    static var empty: WidgetData {
        WidgetData(
            lastUpdated: Date(),
            totalMinutesUsedToday: 0,
            totalDailyBudgetMinutes: 0,
            monthlyData: [],
            topCategories: []
        )
    }
}
