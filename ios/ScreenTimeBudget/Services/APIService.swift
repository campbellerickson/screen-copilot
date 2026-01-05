import Foundation

class APIService {
    private let baseURL = Constants.baseURL
    private let requestTimeout: TimeInterval = 30
    private let maxRetries = 3

    // MARK: - Private Helpers

    private func performRequest<T: Decodable>(
        _ request: URLRequest,
        retries: Int = 3
    ) async throws -> T {
        var lastError: Error?

        for attempt in 0..<retries {
            do {
                var mutableRequest = request
                mutableRequest.timeoutInterval = requestTimeout

                let (data, response) = try await URLSession.shared.data(for: mutableRequest)

                guard let httpResponse = response as? HTTPURLResponse else {
                    throw APIError.invalidResponse
                }

                // Handle HTTP errors
                switch httpResponse.statusCode {
                case 200...299:
                    break // Success
                case 401:
                    throw APIError.unauthorized
                case 404:
                    throw APIError.notFound
                case 500...599:
                    throw APIError.serverError("Server returned \(httpResponse.statusCode)")
                default:
                    throw APIError.invalidResponse
                }

                // Decode response
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601

                do {
                    return try decoder.decode(T.self, from: data)
                } catch {
                    throw APIError.decodingError(error)
                }

            } catch let error as APIError {
                throw error // Don't retry on client errors
            } catch {
                lastError = error
                if attempt < retries - 1 {
                    // Wait before retry (exponential backoff)
                    try await Task.sleep(nanoseconds: UInt64(pow(2.0, Double(attempt))) * 1_000_000_000)
                }
            }
        }

        throw APIError.networkError(lastError ?? URLError(.unknown))
    }

    // MARK: - Budget APIs

    func createBudget(userId: String, monthYear: Date, categories: [CategoryBudgetInput]) async throws -> ScreenTimeBudget {
        guard let url = URL(string: "\(baseURL)/screen-time/budgets") else {
            throw APIError.invalidURL
        }

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

        struct Response: Codable {
            let success: Bool
            let data: ScreenTimeBudget
        }

        let response: Response = try await performRequest(request)
        Analytics.track("budget_created", properties: ["userId": userId])
        return response.data
    }

    func getCurrentBudget(userId: String) async throws -> ScreenTimeBudget? {
        guard let url = URL(string: "\(baseURL)/screen-time/budgets/\(userId)/current") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        struct Response: Codable {
            let success: Bool
            let data: ScreenTimeBudget?
        }

        do {
            let response: Response = try await performRequest(request)
            return response.data
        } catch APIError.notFound {
            return nil // No budget exists yet
        }
    }

    // MARK: - Usage APIs

    func syncUsage(userId: String, usageDate: Date, apps: [AppUsageDTO]) async throws -> SyncResponse {
        guard let url = URL(string: "\(baseURL)/screen-time/usage/sync") else {
            throw APIError.invalidURL
        }

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

        struct Response: Codable {
            let success: Bool
            let data: SyncResponse
        }

        let response: Response = try await performRequest(request)
        Analytics.track("usage_synced", properties: [
            "userId": userId,
            "appsCount": apps.count,
            "date": dateFormatter.string(from: usageDate)
        ])
        return response.data
    }

    func getDailyUsage(userId: String, date: Date) async throws -> BudgetStatusResponse {
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withFullDate]
        let dateString = dateFormatter.string(from: date)

        guard let url = URL(string: "\(baseURL)/screen-time/usage/\(userId)/daily?date=\(dateString)") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        struct Response: Codable {
            let success: Bool
            let data: BudgetStatusResponse
        }

        let response: Response = try await performRequest(request)
        return response.data
    }

    // MARK: - Alert APIs

    func getUserAlerts(userId: String, limit: Int = 10) async throws -> [BudgetAlert] {
        guard let url = URL(string: "\(baseURL)/screen-time/alerts/\(userId)?limit=\(limit)") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        struct Response: Codable {
            let success: Bool
            let data: [BudgetAlert]
        }

        let response: Response = try await performRequest(request)
        return response.data
    }

    func dismissAlert(alertId: String) async throws -> BudgetAlert {
        guard let url = URL(string: "\(baseURL)/screen-time/alerts/\(alertId)/dismiss") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"

        struct Response: Codable {
            let success: Bool
            let data: BudgetAlert
        }

        let response: Response = try await performRequest(request)
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
