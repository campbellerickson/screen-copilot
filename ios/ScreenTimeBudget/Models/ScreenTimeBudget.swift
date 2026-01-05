import Foundation

struct ScreenTimeBudget: Codable, Identifiable {
    let id: String
    let userId: String
    let monthYear: Date
    var categories: [CategoryBudget]
    let isActive: Bool
    let createdAt: Date
    let updatedAt: Date
}

struct CategoryBudget: Codable, Identifiable {
    let id: String
    let budgetId: String
    let categoryName: String
    let categoryType: CategoryType
    let monthlyHours: Double
    var dailyMinutes: Int { // Calculated property
        let daysInMonth = Calendar.current.range(of: .day, in: .month, for: Date())?.count ?? 30
        return Int((monthlyHours * 60) / Double(daysInMonth))
    }
    let isExcluded: Bool
    let createdAt: Date
    let updatedAt: Date
}

struct CategoryBudgetInput: Codable {
    let categoryType: CategoryType
    let categoryName: String
    let monthlyHours: Double
    let isExcluded: Bool
}
