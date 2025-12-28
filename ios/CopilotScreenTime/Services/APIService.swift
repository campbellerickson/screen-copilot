import Foundation

class APIService {
    private let baseURL = Constants.baseURL

    // MARK: - Budget APIs

    func createBudget(userId: String, monthYear: Date, categories: [CategoryBudgetInput]) async throws -> ScreenTimeBudget {
        let url = URL(string: "\(baseURL)/screen-time/budgets")!

        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withFullDate]

        let body: [String: Any] = [
            "userId": userId,
            "monthYear": dateFormatter.string(from: monthYear),
            "categories": categories.map { category in
                [
                    "categoryType": category.categoryType.rawValue,
                    "categoryName": category.categoryName,
                    "monthlyHours": category.monthlyHours,
                    "isExcluded": category.isExcluded
                ]
            }
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, _) = try await URLSession.shared.data(for: request)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        struct Response: Codable {
            let success: Bool
            let data: ScreenTimeBudget
        }

        let response = try decoder.decode(Response.self, from: data)
        return response.data
    }

    func getCurrentBudget(userId: String) async throws -> ScreenTimeBudget? {
        let url = URL(string: "\(baseURL)/screen-time/budgets/\(userId)/current")!

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        let (data, _) = try await URLSession.shared.data(for: request)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        struct Response: Codable {
            let success: Bool
            let data: ScreenTimeBudget?
        }

        let response = try decoder.decode(Response.self, from: data)
        return response.data
    }

    // MARK: - Usage APIs

    func syncUsage(userId: String, usageDate: Date, apps: [AppUsageDTO]) async throws -> SyncResponse {
        let url = URL(string: "\(baseURL)/screen-time/usage/sync")!

        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withFullDate]

        let body: [String: Any] = [
            "userId": userId,
            "usageDate": dateFormatter.string(from: usageDate),
            "apps": apps.map { app in
                [
                    "bundleId": app.bundleId,
                    "appName": app.appName,
                    "totalMinutes": app.totalMinutes
                ]
            }
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, _) = try await URLSession.shared.data(for: request)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        struct Response: Codable {
            let success: Bool
            let data: SyncResponse
        }

        let response = try decoder.decode(Response.self, from: data)
        return response.data
    }

    func getDailyUsage(userId: String, date: Date) async throws -> BudgetStatusResponse {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withFullDate]
        let dateString = dateFormatter.string(from: date)

        let url = URL(string: "\(baseURL)/screen-time/usage/\(userId)/daily?date=\(dateString)")!

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        let (data, _) = try await URLSession.shared.data(for: request)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        struct Response: Codable {
            let success: Bool
            let data: BudgetStatusResponse
        }

        let response = try decoder.decode(Response.self, from: data)
        return response.data
    }

    // MARK: - Alert APIs

    func getUserAlerts(userId: String, limit: Int = 10) async throws -> [BudgetAlert] {
        let url = URL(string: "\(baseURL)/screen-time/alerts/\(userId)?limit=\(limit)")!

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        let (data, _) = try await URLSession.shared.data(for: request)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        struct Response: Codable {
            let success: Bool
            let data: [BudgetAlert]
        }

        let response = try decoder.decode(Response.self, from: data)
        return response.data
    }
}

struct BudgetAlert: Codable {
    let id: String
    let userId: String
    let categoryType: String
    let alertDate: Date
    let overageMinutes: Int
    let alertSentAt: Date
    let wasDismissed: Bool
    let dismissedAt: Date?
}
