//
//  TimeFormatter.swift
//  ScreenTimeBudget
//
//  Helper for formatting time durations
//

import Foundation

struct TimeFormatter {
    /// Format minutes as "Xh Ym"
    static func formatMinutes(_ minutes: Int) -> String {
        let hours = minutes / 60
        let mins = minutes % 60

        if hours > 0 && mins > 0 {
            return "\(hours)h \(mins)m"
        } else if hours > 0 {
            return "\(hours)h"
        } else {
            return "\(mins)m"
        }
    }
}
