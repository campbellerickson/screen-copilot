import Foundation

// Simplified analytics for MVP
class Analytics {
    static func track(_ event: String, properties: [String: Any]? = nil) {
        #if DEBUG
        print("[Analytics] \(event): \(properties ?? [:])")
        #endif
        // TODO: Implement actual analytics (Mixpanel, Amplitude, etc.)
    }
}
