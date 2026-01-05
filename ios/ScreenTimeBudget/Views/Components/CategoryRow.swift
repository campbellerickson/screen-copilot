//
//  CategoryRow.swift
//  ScreenTimeBudget
//
//  Category usage row component
//

import SwiftUI

struct CategoryRow: View {
    let icon: String
    let name: String
    let minutesUsed: Int
    let dailyBudgetMinutes: Int
    let isUnlimited: Bool

    var progress: Double {
        guard dailyBudgetMinutes > 0 else { return 0 }
        return Double(minutesUsed) / Double(dailyBudgetMinutes)
    }

    var progressColor: Color {
        if isUnlimited {
            return .gray
        } else if progress >= 1.0 {
            return .red
        } else if progress >= 0.8 {
            return .orange
        } else {
            return .green
        }
    }

    var formattedTime: String {
        TimeFormatter.formatMinutes(minutesUsed)
    }

    var budgetText: String {
        if isUnlimited {
            return "Unlimited"
        } else {
            return "\(formattedTime) / \(TimeFormatter.formatMinutes(dailyBudgetMinutes))"
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                // Icon and name
                HStack(spacing: 12) {
                    Text(icon)
                        .font(.system(size: 32))

                    Text(name)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }

                Spacer()

                // Time used - larger and bolder
                Text(formattedTime)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(progressColor)
            }

            // Progress bar - thicker
            VStack(alignment: .leading, spacing: 6) {
                ProgressBar(value: progress, color: progressColor, height: 8)

                Text(budgetText)
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.5))
            }
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        CategoryRow(
            icon: "📱",
            name: "Social Media",
            minutesUsed: 80,
            dailyBudgetMinutes: 90,
            isUnlimited: false
        )

        CategoryRow(
            icon: "🎬",
            name: "Entertainment",
            minutesUsed: 45,
            dailyBudgetMinutes: 90,
            isUnlimited: false
        )

        CategoryRow(
            icon: "💼",
            name: "Productivity",
            minutesUsed: 120,
            dailyBudgetMinutes: 0,
            isUnlimited: true
        )
    }
    .padding()
}
