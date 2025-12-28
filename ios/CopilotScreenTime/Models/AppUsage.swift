import Foundation

struct AppUsage: Codable, Identifiable {
    let id: String
    let bundleIdentifier: String
    let appName: String
    let totalMinutes: Int
    let usageDate: Date

    init(id: String = UUID().uuidString, bundleIdentifier: String, appName: String, totalMinutes: Int, usageDate: Date) {
        self.id = id
        self.bundleIdentifier = bundleIdentifier
        self.appName = appName
        self.totalMinutes = totalMinutes
        self.usageDate = usageDate
    }
}

struct AppUsageDTO: Codable {
    let bundleId: String
    let appName: String
    let totalMinutes: Int
}
