//
//  NotificationService.swift
//  ScreenTimeBudget
//
//  Manages local notifications for budget alerts
//

import Foundation
import UserNotifications

class NotificationService: NSObject, ObservableObject {
    static let shared = NotificationService()
    
    enum NotificationCategory: String {
        case dailyOverage = "DAILY_OVERAGE"
        case monthlyOverage = "MONTHLY_OVERAGE"
        
        var identifier: String {
            return rawValue
        }
    }
    
    // Track notifications sent today to prevent duplicates
    private var dailyNotificationsSentToday: Set<String> = []
    private var monthlyNotificationsSentToday: Set<String> = []
    private var lastResetDate: Date?
    
    override init() {
        super.init()
        requestAuthorization()
        setupNotificationCategories()
        resetDailyTrackingIfNeeded()
    }
    
    // MARK: - Authorization
    
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permission granted")
            } else if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
            } else {
                print("Notification permission denied")
            }
        }
    }
    
    // MARK: - Setup
    
    private func setupNotificationCategories() {
        let center = UNUserNotificationCenter.current()
        
        // Daily overage category
        let dailyCategory = UNNotificationCategory(
            identifier: NotificationCategory.dailyOverage.rawValue,
            actions: [],
            intentIdentifiers: [],
            options: []
        )
        
        // Monthly overage category
        let monthlyCategory = UNNotificationCategory(
            identifier: NotificationCategory.monthlyOverage.rawValue,
            actions: [],
            intentIdentifiers: [],
            options: []
        )
        
        center.setNotificationCategories([dailyCategory, monthlyCategory])
    }
    
    // MARK: - Reset Tracking
    
    private func resetDailyTrackingIfNeeded() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        if let lastReset = lastResetDate, calendar.isDate(lastReset, inSameDayAs: Date()) {
            return // Already reset today
        }
        
        dailyNotificationsSentToday.removeAll()
        monthlyNotificationsSentToday.removeAll()
        lastResetDate = today
    }
    
    // MARK: - Schedule Notifications
    
    /**
     * Schedule notifications based on budget overages
     * This is called when the app receives sync data with notifications
     */
    func scheduleNotifications(for notifications: [NotificationAlert]) {
        resetDailyTrackingIfNeeded()
        
        // Remove any pending notifications from previous checks to avoid duplicates
        // We'll add them fresh each time
        
        // Schedule each notification (deduplicated)
        for notification in notifications {
            let key = notification.categoryType
            
            // Check if we've already sent this notification today
            let alreadySent = notification.type == .dailyOverage
                ? dailyNotificationsSentToday.contains(key)
                : monthlyNotificationsSentToday.contains(key)
            
            if !alreadySent {
                scheduleNotification(for: notification)
                
                // Track that we sent it
                if notification.type == .dailyOverage {
                    dailyNotificationsSentToday.insert(key)
                } else {
                    monthlyNotificationsSentToday.insert(key)
                }
            }
        }
    }
    
    private func scheduleNotification(for alert: NotificationAlert) {
        let content = UNMutableNotificationContent()
        content.title = alert.type == .dailyOverage ? "Daily Budget Exceeded" : "Monthly Budget Exceeded"
        content.body = alert.message
        content.sound = .default
        content.categoryIdentifier = alert.type == .dailyOverage 
            ? NotificationCategory.dailyOverage.rawValue
            : NotificationCategory.monthlyOverage.rawValue
        
        // Add user info for handling
        content.userInfo = [
            "type": alert.type.rawValue,
            "categoryType": alert.categoryType,
            "categoryName": alert.categoryName,
            "overageMinutes": alert.overageMinutes
        ]
        
        // Schedule notification immediately (or with slight delay to batch multiple)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        
        // Use unique identifier based on type and category to prevent duplicates
        let identifier = "\(alert.type.rawValue)_\(alert.categoryType)_\(Date().timeIntervalSince1970)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            } else {
                print("Scheduled notification: \(alert.message)")
            }
        }
    }
    
    // MARK: - Notification Management
    
    func removePendingNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    func removeDeliveredNotifications() {
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }
    
    func getPendingNotifications(completion: @escaping ([UNNotificationRequest]) -> Void) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            completion(requests)
        }
    }
    
    // MARK: - Check Authorization Status
    
    func checkAuthorizationStatus(completion: @escaping (UNAuthorizationStatus) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            completion(settings.authorizationStatus)
        }
    }
}
