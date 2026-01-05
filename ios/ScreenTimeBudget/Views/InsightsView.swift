//
//  InsightsView.swift
//  ScreenTimeBudget
//
//  Insights and trends screen
//

import SwiftUI

struct InsightsView: View {
    @StateObject private var viewModel = InsightsViewModel()

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Week summary
                    weekSummarySection

                    // Top apps
                    topAppsSection

                    // Trends
                    trendsSection
                }
                .padding()
            }
            .navigationTitle("Insights")
            .task {
                await viewModel.loadData()
            }
        }
    }

    // MARK: - Week Summary

    private var weekSummarySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("This Week")
                .font(.system(size: 24, weight: .bold))

            HStack(spacing: 16) {
                VStack(spacing: 8) {
                    Text(viewModel.weeklyTotalFormatted)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.primary)

                    Text("Total Time")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.blue.opacity(0.1))
                )

                VStack(spacing: 8) {
                    Text(viewModel.dailyAverageFormatted)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.primary)

                    Text("Daily Average")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.green.opacity(0.1))
                )
            }

            // Week comparison
            HStack(spacing: 8) {
                Image(systemName: viewModel.weekComparisonIcon)
                    .foregroundColor(viewModel.weekComparisonColor)

                Text(viewModel.weekComparisonText)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 4)
        }
    }

    // MARK: - Top Apps

    private var topAppsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Most Used Apps")
                .font(.system(size: 18, weight: .semibold))

            if viewModel.topApps.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "app.badge")
                        .font(.system(size: 48))
                        .foregroundColor(.gray.opacity(0.5))

                    Text("No app data yet")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                VStack(spacing: 12) {
                    ForEach(Array(viewModel.topApps.enumerated()), id: \.element.id) { index, app in
                        HStack(spacing: 12) {
                            // Rank
                            Text("\(index + 1)")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.secondary)
                                .frame(width: 24)

                            // App name
                            Text(app.name)
                                .font(.system(size: 16, weight: .medium))

                            Spacer()

                            // Time
                            Text(TimeFormatter.formatMinutes(app.minutes))
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.primary)
                        }
                        .padding(.vertical, 8)

                        if index < viewModel.topApps.count - 1 {
                            Divider()
                        }
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                )
            }
        }
    }

    // MARK: - Trends

    private var trendsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Patterns")
                .font(.system(size: 18, weight: .semibold))

            VStack(spacing: 12) {
                insightCard(
                    icon: "moon.stars.fill",
                    title: "Peak Usage",
                    description: "You use your phone most between 8-10 PM",
                    color: .purple
                )

                insightCard(
                    icon: "checkmark.circle.fill",
                    title: "Best Day",
                    description: "Tuesday has the lowest screen time",
                    color: .green
                )

                insightCard(
                    icon: "chart.line.uptrend.xyaxis",
                    title: "Trend",
                    description: "Screen time decreased by 15% this month",
                    color: .blue
                )
            }
        }
    }

    private func insightCard(icon: String, title: String, description: String, color: Color) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(color.opacity(0.1))
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))

                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
}

// MARK: - ViewModel

@MainActor
class InsightsViewModel: ObservableObject {
    @Published var weeklyTotal: Int = 0
    @Published var topApps: [TopApp] = []
    @Published var previousWeekTotal: Int = 0

    var weeklyTotalFormatted: String {
        TimeFormatter.formatMinutes(weeklyTotal)
    }

    var dailyAverageFormatted: String {
        TimeFormatter.formatMinutes(weeklyTotal / 7)
    }

    var weekComparisonIcon: String {
        if weeklyTotal < previousWeekTotal {
            return "arrow.down.circle.fill"
        } else if weeklyTotal > previousWeekTotal {
            return "arrow.up.circle.fill"
        } else {
            return "equal.circle.fill"
        }
    }

    var weekComparisonColor: Color {
        if weeklyTotal < previousWeekTotal {
            return .green
        } else if weeklyTotal > previousWeekTotal {
            return .red
        } else {
            return .gray
        }
    }

    var weekComparisonText: String {
        let diff = abs(weeklyTotal - previousWeekTotal)
        let percentage = previousWeekTotal > 0 ? Int((Double(diff) / Double(previousWeekTotal)) * 100) : 0

        if weeklyTotal < previousWeekTotal {
            return "\(percentage)% less than last week"
        } else if weeklyTotal > previousWeekTotal {
            return "\(percentage)% more than last week"
        } else {
            return "Same as last week"
        }
    }

    func loadData() async {
        // Load mock data
        weeklyTotal = 1680 // 28 hours
        previousWeekTotal = 1980 // 33 hours

        topApps = [
            TopApp(name: "Instagram", minutes: 420),
            TopApp(name: "YouTube", minutes: 360),
            TopApp(name: "TikTok", minutes: 280),
            TopApp(name: "Safari", minutes: 220),
            TopApp(name: "Messages", minutes: 180),
        ]

        // TODO: Load from API
    }
}

struct TopApp: Identifiable {
    let id = UUID()
    let name: String
    let minutes: Int
}

#Preview {
    InsightsView()
}
