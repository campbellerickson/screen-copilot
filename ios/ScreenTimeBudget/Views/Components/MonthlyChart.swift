//
//  MonthlyChart.swift
//  ScreenTimeBudget
//
//  Monthly usage line chart
//

import SwiftUI

struct MonthlyChart: View {
    let dataPoints: [DailyUsagePoint]
    let currentDay: Int

    var maxMinutes: Int {
        let usageMax = dataPoints.map { $0.minutes }.max() ?? 240
        let budgetMax = dataPoints.map { $0.budgetMinutes }.max() ?? 240
        return max(usageMax, budgetMax, 240) // At least 4 hours
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("This Month")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
                .tracking(1.2)

            if dataPoints.isEmpty {
                // Empty state
                VStack(spacing: 12) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 48))
                        .foregroundColor(.white.opacity(0.3))

                    Text("No usage data yet")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.6))

                    Text("Check back after syncing your screen time")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.5))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 180)
            } else {
                // Chart
                GeometryReader { geometry in
                    let width = geometry.size.width
                    let height = geometry.size.height
                    let stepX = width / 31 // 31 days max
                    let stepY = height / CGFloat(maxMinutes)

                    ZStack(alignment: .bottomLeading) {
                        // Y-axis labels
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach([4, 3, 2, 1, 0], id: \.self) { hour in
                                Text("\(hour)h")
                                    .font(.system(size: 10))
                                    .foregroundColor(.white.opacity(0.5))
                                    .frame(height: height / 4)
                            }
                        }
                        .offset(x: -25, y: 0)

                        // Budget line (dotted)
                        if let firstBudget = dataPoints.first?.budgetMinutes {
                            Path { path in
                                path.move(to: CGPoint(x: 0, y: height - CGFloat(firstBudget) * stepY))
                                path.addLine(to: CGPoint(x: width, y: height - CGFloat(firstBudget) * stepY))
                            }
                            .stroke(Color.blue.opacity(0.4), style: StrokeStyle(lineWidth: 2, dash: [5, 5]))
                        }

                        // Usage line
                        Path { path in
                            for (index, point) in dataPoints.enumerated() {
                                let x = CGFloat(point.day - 1) * stepX
                                let y = height - CGFloat(point.minutes) * stepY

                                if index == 0 {
                                    path.move(to: CGPoint(x: x, y: y))
                                } else {
                                    path.addLine(to: CGPoint(x: x, y: y))
                                }
                            }
                        }
                        .stroke(
                            LinearGradient(
                                colors: [Color.green, Color.green.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
                        )

                        // Data points
                        ForEach(dataPoints) { point in
                            let x = CGFloat(point.day - 1) * stepX
                            let y = height - CGFloat(point.minutes) * stepY

                            Circle()
                                .fill(point.day == currentDay ? Color.green : Color.green.opacity(0.7))
                                .frame(width: point.day == currentDay ? 8 : 6, height: point.day == currentDay ? 8 : 6)
                                .position(x: x, y: y)
                        }

                        // X-axis labels
                        HStack(spacing: 0) {
                            ForEach([1, 5, 10, 15, 20, 25, 30], id: \.self) { day in
                                Text("\(day)")
                                    .font(.system(size: 10))
                                    .foregroundColor(.white.opacity(0.5))
                                    .frame(width: stepX * 5)
                            }
                        }
                        .offset(x: 0, y: height + 15)
                    }
                }
                .frame(height: 180)
                .padding(.leading, 30)
            }
        }
    }
}

#Preview {
    MonthlyChart(
        dataPoints: [
            DailyUsagePoint(day: 1, minutes: 180, budgetMinutes: 240),
            DailyUsagePoint(day: 2, minutes: 210, budgetMinutes: 240),
            DailyUsagePoint(day: 3, minutes: 150, budgetMinutes: 240),
            DailyUsagePoint(day: 4, minutes: 200, budgetMinutes: 240),
        ],
        currentDay: 4
    )
    .padding()
}
