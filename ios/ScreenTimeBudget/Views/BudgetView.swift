//
//  BudgetView.swift
//  ScreenTimeBudget
//
//  Budget setup and management screen
//

import SwiftUI

struct BudgetView: View {
    @StateObject private var viewModel = BudgetViewModel()
    @State private var showingSaveConfirmation = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header info
                    headerSection

                    // Category budgets
                    categoriesSection

                    // Save button
                    saveButton
                }
                .padding()
            }
            .navigationTitle("Budget")
            .task {
                await viewModel.loadBudget()
            }
            .alert("Budget Saved", isPresented: $showingSaveConfirmation) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Your monthly budget has been updated successfully.")
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Monthly Budget")
                .font(.system(size: 24, weight: .bold))

            Text("Set how many hours per month you want to spend on each category. Your daily budget will be calculated automatically.")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Monthly Budget")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    Text(viewModel.totalMonthlyHoursFormatted)
                        .font(.system(size: 20, weight: .semibold))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("Daily Average")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    Text(viewModel.dailyAverageFormatted)
                        .font(.system(size: 20, weight: .semibold))
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.blue.opacity(0.1))
            )
        }
    }

    // MARK: - Categories Section

    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("CATEGORIES")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.secondary)

            VStack(spacing: 0) {
                ForEach(Array(viewModel.categoryBudgets.enumerated()), id: \.element.id) { index, category in
                    CategoryBudgetRow(
                        category: category,
                        onHoursChange: { newValue in
                            viewModel.updateCategoryHours(at: index, hours: newValue)
                        },
                        onExcludeToggle: {
                            viewModel.toggleCategoryExclude(at: index)
                        }
                    )

                    if index < viewModel.categoryBudgets.count - 1 {
                        Divider()
                            .padding(.leading, 60)
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

    // MARK: - Save Button

    private var saveButton: some View {
        Button(action: {
            Task {
                await viewModel.saveBudget()
                showingSaveConfirmation = true
            }
        }) {
            HStack {
                if viewModel.isSaving {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text("Save Budget")
                        .font(.system(size: 17, weight: .semibold))
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(12)
        }
        .disabled(viewModel.isSaving)
    }
}

// MARK: - Category Budget Row

struct CategoryBudgetRow: View {
    let category: CategoryBudgetItem
    let onHoursChange: (Double) -> Void
    let onExcludeToggle: () -> Void

    @State private var hoursText: String

    init(category: CategoryBudgetItem, onHoursChange: @escaping (Double) -> Void, onExcludeToggle: @escaping () -> Void) {
        self.category = category
        self.onHoursChange = onHoursChange
        self.onExcludeToggle = onExcludeToggle
        self._hoursText = State(initialValue: category.isExcluded ? "0" : String(format: "%.0f", category.monthlyHours))
    }

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Text(category.icon)
                .font(.title2)
                .frame(width: 36)

            // Name and daily budget
            VStack(alignment: .leading, spacing: 4) {
                Text(category.name)
                    .font(.system(size: 16, weight: .medium))

                if !category.isExcluded {
                    Text("\(category.dailyMinutesFormatted) per day")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                } else {
                    Text("Excluded")
                        .font(.system(size: 12))
                        .foregroundColor(.orange)
                }
            }

            Spacer()

            // Hours input
            if !category.isExcluded {
                HStack(spacing: 4) {
                    TextField("0", text: $hoursText)
                        .keyboardType(.numberPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 50)
                        .textFieldStyle(.roundedBorder)
                        .onChange(of: hoursText) { newValue in
                            if let hours = Double(newValue) {
                                onHoursChange(hours)
                            }
                        }

                    Text("h/mo")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
            }

            // Exclude toggle
            Toggle("", isOn: Binding(
                get: { category.isExcluded },
                set: { _ in
                    onExcludeToggle()
                    hoursText = category.isExcluded ? String(format: "%.0f", category.monthlyHours) : "0"
                }
            ))
            .labelsHidden()
        }
        .padding(.vertical, 8)
        .opacity(category.isExcluded ? 0.5 : 1.0)
    }
}

// MARK: - ViewModel

@MainActor
class BudgetViewModel: ObservableObject {
    @Published var categoryBudgets: [CategoryBudgetItem] = []
    @Published var isSaving = false

    private let apiService = APIService()

    var totalMonthlyHours: Double {
        categoryBudgets.filter { !$0.isExcluded }.reduce(0) { $0 + $1.monthlyHours }
    }

    var totalMonthlyHoursFormatted: String {
        "\(Int(totalMonthlyHours))h"
    }

    var dailyAverageFormatted: String {
        let daysInMonth = Calendar.current.range(of: .day, in: .month, for: Date())?.count ?? 30
        let dailyMinutes = (totalMonthlyHours * 60) / Double(daysInMonth)
        return TimeFormatter.formatMinutes(Int(dailyMinutes))
    }

    init() {
        // Initialize with default categories
        categoryBudgets = CategoryType.allCases.map { type in
            CategoryBudgetItem(
                categoryType: type,
                monthlyHours: type.defaultBudget,
                isExcluded: type.defaultBudget == 0
            )
        }
    }

    func loadBudget() async {
        // Load existing budget from backend
        // TODO: Implement API call
        /*
        do {
            let userId = UserManager.shared.userId
            if let budget = try await apiService.getCurrentBudget(userId: userId) {
                // Update categoryBudgets with loaded data
            }
        } catch {
            print("Error loading budget: \(error)")
        }
        */
    }

    func saveBudget() async {
        isSaving = true
        defer { isSaving = false }

        // Save to backend
        // TODO: Implement API call
        /*
        do {
            let userId = UserManager.shared.userId
            let monthYear = Date()
            let categories = categoryBudgets.map { category in
                CategoryBudgetInput(
                    categoryType: category.categoryType,
                    categoryName: category.name,
                    monthlyHours: category.monthlyHours,
                    isExcluded: category.isExcluded
                )
            }

            _ = try await apiService.createBudget(userId: userId, monthYear: monthYear, categories: categories)
        } catch {
            print("Error saving budget: \(error)")
        }
        */

        // Simulate save delay
        try? await Task.sleep(nanoseconds: 1_000_000_000)
    }

    func updateCategoryHours(at index: Int, hours: Double) {
        guard index < categoryBudgets.count else { return }
        categoryBudgets[index].monthlyHours = max(0, hours)
    }

    func toggleCategoryExclude(at index: Int) {
        guard index < categoryBudgets.count else { return }
        categoryBudgets[index].isExcluded.toggle()
        if categoryBudgets[index].isExcluded {
            categoryBudgets[index].monthlyHours = 0
        }
    }
}

struct CategoryBudgetItem: Identifiable {
    let id = UUID()
    let categoryType: CategoryType
    var monthlyHours: Double
    var isExcluded: Bool

    var name: String {
        categoryType.displayName
    }

    var icon: String {
        categoryType.icon
    }

    var dailyMinutesFormatted: String {
        let daysInMonth = Calendar.current.range(of: .day, in: .month, for: Date())?.count ?? 30
        let dailyMinutes = (monthlyHours * 60) / Double(daysInMonth)
        return TimeFormatter.formatMinutes(Int(dailyMinutes))
    }
}

#Preview {
    BudgetView()
}
