//
//  ProgressBar.swift
//  ScreenTimeBudget
//
//  Reusable progress bar component
//

import SwiftUI

struct ProgressBar: View {
    let value: Double // 0.0 to 1.0
    let color: Color
    let height: CGFloat

    init(value: Double, color: Color = .blue, height: CGFloat = 8) {
        self.value = min(max(value, 0), 1) // Clamp between 0 and 1
        self.color = color
        self.height = height
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(Color.gray.opacity(0.2))
                    .frame(height: height)

                // Progress
                RoundedRectangle(cornerRadius: height / 2)
                    .fill(color)
                    .frame(width: geometry.size.width * value, height: height)
                    .animation(.easeInOut(duration: 0.3), value: value)
            }
        }
        .frame(height: height)
    }
}

struct CircularProgressBar: View {
    let progress: Double // 0.0 to 1.0
    let color: Color
    let lineWidth: CGFloat

    init(progress: Double, color: Color = .blue, lineWidth: CGFloat = 12) {
        self.progress = min(max(progress, 0), 1)
        self.color = color
        self.lineWidth = lineWidth
    }

    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: lineWidth)

            // Progress circle
            Circle()
                .trim(from: 0, to: progress)
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: progress)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        ProgressBar(value: 0.7, color: .green)
            .frame(height: 8)

        CircularProgressBar(progress: 0.65, color: .blue)
            .frame(width: 100, height: 100)
    }
    .padding()
}
