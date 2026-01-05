//
//  APIError.swift
//  ScreenTimeBudget
//
//  Error types for API interactions
//

import Foundation

enum APIError: LocalizedError {
    case invalidURL
    case networkError(Error)
    case invalidResponse
    case serverError(String)
    case decodingError(Error)
    case unauthorized
    case notFound
    case timeout

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from server"
        case .serverError(let message):
            return "Server error: \(message)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .unauthorized:
            return "Unauthorized request"
        case .notFound:
            return "Resource not found"
        case .timeout:
            return "Request timed out"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .networkError:
            return "Check your internet connection and try again"
        case .timeout:
            return "The request took too long. Please try again"
        case .unauthorized:
            return "Please log in again"
        case .serverError:
            return "Please try again later or contact support"
        default:
            return "Please try again"
        }
    }
}
