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
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center) {
                // Icon and name
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(progressColor.opacity(0.15))
                            .frame(width: 50, height: 50)

                        Text(icon)
                            .font(.system(size: 28))
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text(name)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)

                        Text(budgetText)
                            .font(.system(size: 13))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }

                Spacer()

                // Time used - larger and bolder
                VStack(alignment: .trailing, spacing: 2) {
                    Text(formattedTime)
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(progressColor)

                    if !isUnlimited {
                        Text("\(Int(progress * 100))%")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(progressColor.opacity(0.7))
                    }
                }
            }

            // Progress bar - thicker and more prominent
            ProgressBar(value: progress, color: progressColor, height: 10)
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
