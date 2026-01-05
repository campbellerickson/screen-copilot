import Foundation
import SwiftUI

struct BudgetStatusResponse: Codable {
    let date: String
    let totalMinutes: Int
    let categories: [String: CategoryStatus]
}

struct CategoryStatus: Codable {
    let totalMinutes: Int
    let dailyBudget: Int
    let monthlyBudget: Int
    let monthlyUsed: Int
    let status: UsageStatus
    let apps: [AppMinutes]

    var statusColor: Color {
        switch status {
        case .under: return .green
        case .atLimit: return .yellow
        case .over: return .red
        }
    }
}

struct AppMinutes: Codable {
    let name: String
    let minutes: Int
}

enum UsageStatus: String, Codable {
    case under = "under"
    case atLimit = "at_limit"
    case over = "over"
}

struct SyncResponse: Codable {
    let synced: Int
    let budgetStatus: [String: CategoryBudgetStatus]
    let alertsTriggered: [AlertDTO]
}

struct CategoryBudgetStatus: Codable {
    let usedToday: Int
    let dailyBudget: Int
    let remaining: Int
    let status: String
}

struct AlertDTO: Codable {
    let category: String
    let overageMinutes: Int
}
