//
//  StreakBadge.swift
//  ScreenTimeBudget
//
//  Streak display component
//

import SwiftUI

struct StreakBadge: View {
    let currentStreak: Int
    let longestStreak: Int
    
    var body: some View {
        HStack(spacing: 12) {
            // Fire icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.orange, Color.red],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)
                    .shadow(color: .orange.opacity(0.3), radius: 8, x: 0, y: 4)
                
                Image(systemName: "flame.fill")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("\(currentStreak) day streak")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Best: \(longestStreak) days")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.25, green: 0.15, blue: 0.1),
                            Color(red: 0.2, green: 0.1, blue: 0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
        )
    }
}

#Preview {
    VStack(spacing: 20) {
        StreakBadge(currentStreak: 7, longestStreak: 12)
        StreakBadge(currentStreak: 30, longestStreak: 30)
    }
    .padding()
    .background(Color(red: 0.05, green: 0.1, blue: 0.15))
}

