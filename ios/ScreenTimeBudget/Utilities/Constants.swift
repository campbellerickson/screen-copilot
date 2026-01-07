import Foundation

struct Constants {
    // API Configuration
    #if DEBUG
    // Local development - LOCAL TESTING BRANCH
    // For iOS Simulator: use localhost
    // For Physical Device: use your Mac's IP address (192.168.68.67)
    static let baseURL = "http://localhost:3000/api/v1"
    // For physical device, uncomment and use:
    // static let baseURL = "http://192.168.68.67:3000/api/v1"
    #else
    // Production - Vercel Deployment
    static let baseURL = "https://screen-copilot-ysge.vercel.app/api/v1"
    #endif

    // Background Tasks
    static let backgroundSyncTaskIdentifier = "com.campbell.ScreenTimeCopilot.sync"

    // App Groups
    static let appGroupIdentifier = "group.com.campbell.ScreenTimeCopilot"

    // Shared Container
    static let screenTimeDataFileName = "screen_time_data.json"

    // Notifications
    static let dataReadyNotificationName = "com.campbell.ScreenTimeCopilot.dataReady"
}

enum CategoryType: String, Codable, CaseIterable {
    case socialMedia = "social_media"
    case entertainment = "entertainment"
    case gaming = "gaming"
    case productivity = "productivity"
    case shopping = "shopping"
    case newsReading = "news_reading"
    case healthFitness = "health_fitness"
    case other = "other"

    var displayName: String {
        switch self {
        case .socialMedia: return "Social Media"
        case .entertainment: return "Entertainment"
        case .gaming: return "Gaming"
        case .productivity: return "Productivity"
        case .shopping: return "Shopping"
        case .newsReading: return "News & Reading"
        case .healthFitness: return "Health & Fitness"
        case .other: return "Other"
        }
    }

    var icon: String {
        switch self {
        case .socialMedia: return "person.2.fill"
        case .entertainment: return "tv.fill"
        case .gaming: return "gamecontroller.fill"
        case .productivity: return "briefcase.fill"
        case .shopping: return "cart.fill"
        case .newsReading: return "newspaper.fill"
        case .healthFitness: return "heart.fill"
        case .other: return "app.fill"
        }
    }

    var defaultBudget: Double {
        switch self {
        case .socialMedia: return 30
        case .entertainment: return 40
        case .gaming: return 20
        case .productivity: return 0 // Often excluded
        case .shopping: return 10
        case .newsReading: return 15
        case .healthFitness: return 0 // Often excluded
        case .other: return 10
        }
    }
}
