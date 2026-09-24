import SwiftData
import SwiftUI

/// Eine Periode im Detail (SPEC 4.4): Betrag, Ausgaben, Ergebnis, Balken je
/// Kategorie und alle Buchungen – bearbeitbar wie auf dem Hauptbildschirm.
struct PeriodDetailView: View {
    let period: BudgetPeriod

    @Environment(\.today) private var today
    @Query private var amounts: [BudgetAmount]
    @Query private var expenses: [Expense]
    /// Frühere Perioden desselben Budgetjahrs – für das Defizit (SPEC 2.5).
    @Query private var earlierExpenses: [Expense]
    @State private var editorTarget: ExpenseEditorTarget?

    init(period: BudgetPeriod) {
        self.period = period
        let start = period.start
        let end = period.end
        _expenses = Query(
            filter: #Predicate<Expense> { $0.date >= start && $0.date < end },
            sort: [SortDescriptor(\Expense.date, order: .reverse), SortDescriptor(\Expense.createdAt, order: .reverse)]
        )
        let yearStart = period.firstOfBudgetYear().start
        _earlierExpenses = Query(filter: #Predicate<Expense> { $0.date >= yearStart && $0.date < start })
    }

    /// Defizit vor und nach dieser Periode.
    private var deficits: (before: Int, after: Int) {
        let ledger = BudgetLedger(
            settings: amounts.map(\.setting),
            expenses: (earlierExpenses + expenses).map { (date: $0.date, rappen: $0.amountRappen) }
        )
        let isRunning = period.contains(today)
        return (ledger.deficit(before: period), isRunning ? 0 : ledger.deficit(after: period))
    }

    private var summary: BudgetSummary {
        BudgetMath.summary(
            for: period,
            amountRappen: BudgetMath.amount(for: period, in: amounts.map(\.setting)) ?? 0,
            spentRappen: expenses.reduce(0) { $0 + $1.amountRappen },
            today: today
        )
    }

    /// Summe je Kategorie, absteigend. Buchungen ohne Kategorie zählen als „Diverses".
    private var categoryTotals: [CategoryTotalRow] {
        var displays: [String: CategoryDisplay] = [:]
        let items: [(key: String, rappen: Int)] = expenses.map { expense in
            let key = expense.category?.id.uuidString ?? CategorySeed.fallbackID.uuidString
            if displays[key] == nil {
                displays[key] = CategoryDisplay(expense.category)
            }
            return (key: key, rappen: expense.amountRappen)
        }
        return BudgetMath.totals(items).compactMap { total in
            displays[total.key].map { CategoryTotalRow(id: total.key, display: $0, rappen: total.rappen) }
        }
    }

    var body: some View {
        List {
            Section {
                VStack(spacing: 10) {
                    LabeledValueRow(label: "Betrag") {
                        Text(MoneyFormat.chf(summary.amountRappen)).monospacedDigit()
                    }
                    LabeledValueRow(label: "Usgabe") {
                        Text(MoneyFormat.chf(summary.spentRappen)).monospacedDigit()
                    }
                    Divider().overlay(Theme.separator)
                    LabeledValueRow(label: "Ergäbnis") {
                        ResultLabel(summary: summary, isCurrent: period.contains(today))
                    }
                    let deficits = self.deficits
                    if deficits.before > 0 || deficits.after > 0 {
                        Divider().overlay(Theme.separator)
                        LabeledValueRow(label: "Defizit vorhär") {
                            Text(MoneyFormat.chf(deficits.before)).monospacedDigit()
                        }
                        if !period.contains(today) {
                            LabeledValueRow(label: "Defizit nachhär") {
                                Text(MoneyFormat.chf(deficits.after))
                                    .monospacedDigit()
                                    .foregroundStyle(deficits.after > 0 ? Theme.negative : Theme.accent)
                            }
                        }
                    }
                }
                .listRowBackground(Theme.surface)
            } header: {
                Text("\(period.title()) · \(period.rangeText())")
            }

            if !categoryTotals.isEmpty {
                Section("Nach Kategorie") {
                    let total = max(summary.spentRappen, 1)
                    ForEach(categoryTotals) { entry in
                        BarRow(
                            title: entry.display.name,
                            symbolName: entry.display.symbol,
                            color: entry.display.color,
                            fraction: Double(entry.rappen) / Double(total),
                            primaryText: MoneyFormat.chf(entry.rappen),
                            secondaryText: "\(Int((Double(entry.rappen) / Double(total) * 100).rounded())) %"
                        )
                        .padding(.vertical, 4)
                        .listRowBackground(Theme.surface)
                    }
                }
            }

            if expenses.isEmpty {
                Section {
                    EmptyStateView(symbol: "tray", title: "Kei Buechige i dere Periode")
                        .listRowBackground(Color.clear)
                }
            } else {
                ExpenseSections(expenses: expenses, editorTarget: $editorTarget)
            }
        }
        .listStyle(.insetGrouped)
        .themedList()
        .navigationTitle(period.title())
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $editorTarget) { target in
            ExpenseEditorView(expense: target.expense)
        }
    }
}

/// Eine Zeile in „Nach Kategorie“.
struct CategoryTotalRow: Identifiable {
    let id: String
    let display: CategoryDisplay
    let rappen: Int
}
