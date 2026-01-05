//
//  UserManager.swift
//  ScreenTimeBudget
//
//  Manages user ID and persistence
//

import Foundation

class UserManager {
    static let shared = UserManager()

    private let userIdKey = "com.copilot.screentime.userId"

    private init() {}

    /// Get or create user ID
    var userId: String {
        if let existingId = UserDefaults.standard.string(forKey: userIdKey) {
            return existingId
        }

        // Generate new UUID for this user
        let newId = UUID().uuidString
        UserDefaults.standard.set(newId, forKey: userIdKey)

        Analytics.track("user_created", properties: ["userId": newId])

        return newId
    }

    /// Reset user (for testing or logout)
    func resetUser() {
        UserDefaults.standard.removeObject(forKey: userIdKey)
        Analytics.track("user_reset")
    }
}
