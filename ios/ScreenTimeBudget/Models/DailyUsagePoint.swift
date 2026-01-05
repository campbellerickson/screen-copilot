//
//  DailyUsagePoint.swift
//  ScreenTimeBudget
//
//  Model for daily usage data points
//

import Foundation

struct DailyUsagePoint: Codable, Identifiable {
    let id = UUID()
    let day: Int // Day of month (1-31)
    let minutes: Int
    let budgetMinutes: Int

    enum CodingKeys: String, CodingKey {
        case day, minutes, budgetMinutes
    }
}
