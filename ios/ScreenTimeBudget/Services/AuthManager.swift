//
//  AuthManager.swift
//  ScreenTimeBudget
//
//  Manages user authentication and token storage
//

import Foundation
import Security

class AuthManager: ObservableObject {
    static let shared = AuthManager()

    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var authToken: String?

    private let tokenKey = "com.campbell.screentime.authToken"
    private let userKey = "com.campbell.screentime.currentUser"

    init() {
        loadStoredAuth()
    }

    // MARK: - Token Management

    func saveToken(_ token: String) {
        authToken = token
        isAuthenticated = true

        // Store in Keychain
        let data = Data(token.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: tokenKey,
            kSecValueData as String: data
        ]

        // Delete existing item
        SecItemDelete(query as CFDictionary)

        // Add new item
        SecItemAdd(query as CFDictionary, nil)
    }

    func getToken() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: tokenKey,
            kSecReturnData as String: true
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let token = String(data: data, encoding: .utf8) else {
            return nil
        }

        return token
    }

    func deleteToken() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: tokenKey
        ]
        SecItemDelete(query as CFDictionary)

        authToken = nil
        isAuthenticated = false
    }

    // MARK: - User Management

    func saveUser(_ user: User) {
        currentUser = user

        // Store in UserDefaults
        if let encoded = try? JSONEncoder().encode(user) {
            UserDefaults.standard.set(encoded, forKey: userKey)
        }
    }

    func loadStoredAuth() {
        // Load token from Keychain
        if let token = getToken() {
            authToken = token
            isAuthenticated = true
        }

        // Load user from UserDefaults
        if let data = UserDefaults.standard.data(forKey: userKey),
           let user = try? JSONDecoder().decode(User.self, from: data) {
            currentUser = user
        }
    }

    // MARK: - Auth Actions

    func login(email: String, password: String) async throws -> LoginResponse {
        let apiService = APIService()
        let response: LoginResponse = try await apiService.performAuthRequest(
            path: "/auth-login",
            method: "POST",
            body: ["email": email, "password": password]
        )

        saveToken(response.data.token)
        saveUser(response.data.user)

        return response
    }

    func signup(email: String, password: String, name: String?) async throws -> LoginResponse {
        let apiService = APIService()
        var body: [String: Any] = ["email": email, "password": password]
        if let name = name {
            body["name"] = name
        }

        let response: LoginResponse = try await apiService.performAuthRequest(
            path: "/auth-signup",
            method: "POST",
            body: body
        )

        saveToken(response.data.token)
        saveUser(response.data.user)

        return response
    }

    func logout() {
        deleteToken()
        currentUser = nil
        UserDefaults.standard.removeObject(forKey: userKey)
    }
}

// MARK: - Models

struct User: Codable {
    let id: String
    let email: String
    let name: String?
    let profileImage: String?
    let createdAt: String?
}

struct LoginResponse: Codable {
    let success: Bool
    let data: LoginData
}

struct LoginData: Codable {
    let user: User
    let token: String
    let subscription: SubscriptionStatus
}

struct SubscriptionStatus: Codable {
    let status: String
    let hasAccess: Bool
    let trialEndDate: String?
    let daysRemaining: Int?
    let renewalDate: String?
}
