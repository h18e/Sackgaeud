import SwiftData
import SwiftUI

/// Erfassen und Bearbeiten einer Buchung (SPEC 4.3).
///
/// Ziel: unter 5 Sekunden vom Antippen bis zum Sichern. Deshalb ist das Betragsfeld
/// sofort aktiv, die zuletzt benutzte Kategorie vorgewählt und das Datum steht auf
/// heute.
struct ExpenseEditorView: View {
    let expense: Expense?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(\.today) private var today
    @Environment(UndoController.self) private var undo

    @Query(sort: \SpendingCategory.sortOrder) private var categories: [SpendingCategory]

    /// Vorauswahl beim nächsten Erfassen. Pro Gerät, nicht synchronisiert (SPEC 3.4).
    @AppStorage("lastCategoryID") private var lastCategoryID = ""

    @State private var amountText: String
    @State private var date: Date
    @State private var selectedCategoryID: UUID?
    @FocusState private var amountFocused: Bool

    init(expense: Expense?) {
        self.expense = expense
        _amountText = State(initialValue: expense.map { MoneyFormat.inputText($0.amountRappen) } ?? "")
        _date = State(initialValue: expense?.date ?? .now)
        _selectedCategoryID = State(initialValue: expense?.category?.id)
    }

    private var amountRappen: Int? { MoneyFormat.parse(amountText) }
    private var isEditing: Bool { expense != nil }

    private var selectedCategory: SpendingCategory? {
        categories.first { $0.id == selectedCategoryID }
    }

    /// Ende von heute – zukünftige Daten sind nicht möglich (SPEC 9, Punkt 3).
    private var latestDate: Date {
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: today)) ?? today
        return tomorrow.addingTimeInterval(-1)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    amountField
                    categoryGrid
                    dateRow
                    if isEditing {
                        deleteButton
                    }
                }
                .padding(16)
            }
            .scrollDismissesKeyboard(.interactively)
            .screenBackground()
            .navigationTitle(isEditing ? "Buechig bearbeite" : "Usgab erfasse")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbräche") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Sichere", action: save)
                        .fontWeight(.semibold)
                        .disabled(amountRappen == nil)
                }
            }
        }
        .presentationDetents([.large])
        .onAppear {
            preselectCategory()
            if !isEditing { amountFocused = true }
        }
        .onChange(of: categories.count) { _, _ in
            preselectCategory()
        }
    }

    // MARK: - Teile

    private var amountField: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text("CHF")
                .font(.title2)
                .foregroundStyle(Theme.textSecondary)
            TextField("0.00", text: $amountText)
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .keyboardType(.decimalPad)
                .focused($amountFocused)
                .foregroundStyle(Theme.textPrimary)
                .accessibilityLabel("Betrag i Franke")
        }
        .card()
    }

    private var categoryGrid: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Kategorie")
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 10)], spacing: 10) {
                ForEach(categories) { category in
                    CategoryTile(
                        category: category,
                        isSelected: category.id == selectedCategoryID
                    ) {
                        selectedCategoryID = category.id
                    }
                }
            }
        }
    }

    private var dateRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            DatePicker("Datum", selection: $date, in: ...latestDate, displayedComponents: .date)
                .environment(\.locale, Locale(identifier: "de_CH"))
                .foregroundStyle(Theme.textPrimary)
                .card(padding: 12)

            let period = BudgetPeriod(containing: date)
            if period != BudgetPeriod(containing: today) {
                Label("Chunnt i \(period.title())", systemImage: "arrow.uturn.backward")
                    .font(.footnote)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
    }

    private var deleteButton: some View {
        Button(role: .destructive) {
            guard let expense else { return }
            let deleted = BudgetRepository(context: context).delete(expense)
            undo.offer(deleted)
            dismiss()
        } label: {
            Label("Buechig lösche", systemImage: "trash")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .tint(Theme.negative)
        .padding(.top, 8)
    }

    // MARK: - Aktionen

    /// Beim Bearbeiten die Kategorie der Buchung, sonst die zuletzt benutzte, sonst
    /// „Diverses", sonst die erste.
    private func preselectCategory() {
        guard selectedCategory == nil else { return }
        if isEditing, expense?.category == nil {
            selectedCategoryID = categories.first(where: \.isFallback)?.id
            return
        }
        let last = UUID(uuidString: lastCategoryID)
        selectedCategoryID = categories.first { $0.id == last }?.id
            ?? categories.first(where: \.isFallback)?.id
            ?? categories.first?.id
    }

    private func save() {
        guard let amountRappen else { return }
        let repository = BudgetRepository(context: context)
        let category = selectedCategory
        if let expense {
            repository.update(expense, amountRappen: amountRappen, date: date, category: category)
        } else {
            repository.addExpense(amountRappen: amountRappen, date: date, category: category)
        }
        if let category {
            lastCategoryID = category.id.uuidString
        }
        dismiss()
    }
}

/// Antippbare Kachel im Kategorie-Raster.
private struct CategoryTile: View {
    let category: SpendingCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: category.symbol)
                    .font(.title3)
                    .foregroundStyle(category.color)
                Text(category.name)
                    .font(.footnote)
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isSelected ? category.color.opacity(0.18) : Theme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isSelected ? category.color : Theme.separator, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(category.name)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
