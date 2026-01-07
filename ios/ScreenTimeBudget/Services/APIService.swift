//
//  APIService.swift
//  ScreenTimeBudget
//
//  API service for backend communication
//

import Foundation

class APIService {
    private let baseURL = Constants.baseURL
    private let requestTimeout: TimeInterval = 30
    private let maxRetries = 3

    // MARK: - Private Helpers

    private func addAuthHeader(to request: inout URLRequest) {
        if let token = AuthManager.shared.authToken {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
    }

    func performAuthRequest<T: Decodable>(
        path: String,
        method: String,
        body: [String: Any]? = nil
    ) async throws -> T {
        guard let url = URL(string: "\(baseURL)\(path)") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if let body = body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }

        return try await performRequest(request, retries: maxRetries)
    }

    private func performRequest<T: Decodable>(
        _ request: URLRequest,
        retries: Int = 3
    ) async throws -> T {
        var lastError: Error?

        for attempt in 0..<retries {
            do {
                var mutableRequest = request
                mutableRequest.timeoutInterval = requestTimeout
                addAuthHeader(to: &mutableRequest)

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

    // MARK: - Subscription APIs

    func getSubscriptionStatus() async throws -> SubscriptionStatusResponse {
        guard let url = URL(string: "\(baseURL)/subscription-status") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        addAuthHeader(to: &request)

        struct Response: Codable {
            let success: Bool
            let data: SubscriptionStatusData
        }

        struct SubscriptionStatusData: Codable {
            let status: String
            let hasAccess: Bool
            let platform: String?
            let trialEndDate: String?
            let renewalDate: String?
            let priceUSD: Double?
            let message: String
        }

        let response: Response = try await performRequest(request)
        
        return SubscriptionStatusResponse(
            status: response.data.status,
            hasAccess: response.data.hasAccess,
            platform: response.data.platform,
            trialEndDate: response.data.trialEndDate,
            renewalDate: response.data.renewalDate,
            priceUSD: response.data.priceUSD,
            message: response.data.message
        )
    }

    func validateReceipt(receiptData: String, transactionId: String) async throws -> ReceiptValidationResponse {
        guard let url = URL(string: "\(baseURL)/subscription-validate-receipt") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        addAuthHeader(to: &request)
        request.httpBody = try JSONSerialization.data(withJSONObject: [
            "receiptData": receiptData,
            "transactionId": transactionId
        ])

        struct Response: Codable {
            let success: Bool
            let data: ReceiptValidationResponse
        }

        let response: Response = try await performRequest(request)
        return response.data
    }

    func cancelSubscription() async throws {
        guard let url = URL(string: "\(baseURL)/subscription-cancel") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        addAuthHeader(to: &request)

        struct Response: Codable {
            let success: Bool
            let message: String?
        }

        let _: Response = try await performRequest(request)
    }

    // MARK: - Account APIs

    func deleteAccount() async throws {
        guard let url = URL(string: "\(baseURL)/auth-delete-account") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "DELETE"
        addAuthHeader(to: &request)

        struct Response: Codable {
            let success: Bool
            let message: String?
        }

        let _: Response = try await performRequest(request)
    }

    // MARK: - Budget APIs

    func createBudget(userId: String, monthYear: Date, categories: [CategoryBudgetInput]) async throws -> ScreenTimeBudget? {
        guard let url = URL(string: "\(baseURL)/budget-create") else {
            throw APIError.invalidURL
        }

        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withFullDate]

        let body: [String: Any] = [
            "userId": userId,
            "monthYear": dateFormatter.string(from: monthYear),
            "categories": categories.map { cat in
                [
                    "categoryType": cat.categoryType.rawValue,
                    "categoryName": cat.categoryName,
                    "monthlyHours": cat.monthlyHours,
                    "isExcluded": cat.isExcluded
                ]
            }
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        addAuthHeader(to: &request)
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

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
        guard let url = URL(string: "\(baseURL)/usage-sync") else {
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
        addAuthHeader(to: &request)
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        struct Response: Codable {
            let success: Bool
            let data: SyncResponse
        }

        let response: Response = try await performRequest(request)
        
        // Schedule notifications if any
        if let notifications = response.data.notifications, !notifications.isEmpty {
            NotificationService.shared.scheduleNotifications(for: notifications)
        }
        
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

        guard let url = URL(string: "\(baseURL)/usage-daily?date=\(dateString)") else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        addAuthHeader(to: &request)

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
        addAuthHeader(to: &request)

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
        addAuthHeader(to: &request)

        struct Response: Codable {
            let success: Bool
            let data: BudgetAlert
        }

        let response: Response = try await performRequest(request)
        return response.data
    }
}

// MARK: - Response Models

struct SubscriptionStatusResponse: Codable {
    let status: String
    let hasAccess: Bool
    let platform: String?
    let trialEndDate: String?
    let renewalDate: String?
    let priceUSD: Double?
    let message: String
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
