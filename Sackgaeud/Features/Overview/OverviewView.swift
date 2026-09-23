import SwiftData
import SwiftUI

/// Hauptbildschirm (SPEC 4.2): Periode, Restbetrag, Tagesbudget, Buchungen, Plus-Knopf.
struct OverviewView: View {
    @Environment(\.today) private var today
    @State private var editorTarget: ExpenseEditorTarget?
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            // Eigene Unteransicht, weil die @Query von der Periode abhängt und die sich
            // am 25. ändert. Die `id` baut sie dann mit der neuen Periode neu auf.
            OverviewContent(period: BudgetPeriod(containing: today), editorTarget: $editorTarget)
                .id(BudgetPeriod(containing: today).key)
                .navigationTitle("Sackgäud")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        NavigationLink(value: Destination.history) {
                            Image(systemName: "clock.arrow.circlepath")
                        }
                        .accessibilityLabel("Verlouf")
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        NavigationLink(value: Destination.settings) {
                            Image(systemName: "gearshape")
                        }
                        .accessibilityLabel("Istellige")
                    }
                }
                .navigationDestination(for: Destination.self) { destination in
                    switch destination {
                    case .history: HistoryView()
                    case .settings: SettingsView()
                    }
                }
                .safeAreaInset(edge: .bottom) {
                    Button {
                        editorTarget = ExpenseEditorTarget(expense: nil)
                    } label: {
                        Label("Usgab erfasse", systemImage: "plus")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.accent)
                    .foregroundStyle(Theme.background)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 8)
                }
        }
        .sheet(item: $editorTarget) { target in
            ExpenseEditorView(expense: target.expense)
        }
    }

    enum Destination: Hashable {
        case history
        case settings
    }
}

/// Inhalt des Hauptbildschirms für eine feste Periode.
private struct OverviewContent: View {
    let period: BudgetPeriod
    @Binding var editorTarget: ExpenseEditorTarget?

    @Environment(\.today) private var today
    @Query private var amounts: [BudgetAmount]
    @Query private var expenses: [Expense]

    init(period: BudgetPeriod, editorTarget: Binding<ExpenseEditorTarget?>) {
        self.period = period
        _editorTarget = editorTarget
        let start = period.start
        let end = period.end
        _expenses = Query(
            filter: #Predicate<Expense> { $0.date >= start && $0.date < end },
            sort: [SortDescriptor(\Expense.date, order: .reverse), SortDescriptor(\Expense.createdAt, order: .reverse)]
        )
    }

    private var summary: BudgetSummary {
        BudgetMath.summary(
            for: period,
            amountRappen: BudgetMath.amount(for: period, in: amounts.map(\.setting)) ?? 0,
            spentRappen: expenses.reduce(0) { $0 + $1.amountRappen },
            today: today
        )
    }

    var body: some View {
        List {
            Section {
                RestCard(period: period, summary: summary)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }

            if expenses.isEmpty {
                Section {
                    EmptyStateView(
                        symbol: "tray",
                        title: "No nüt erfasst",
                        message: "Tipp uf „Usgab erfasse“, sobald du öppis zahlt hesch."
                    )
                    .listRowBackground(Color.clear)
                }
            } else {
                ExpenseSections(expenses: expenses, editorTarget: $editorTarget)
            }
        }
        .listStyle(.insetGrouped)
        .themedList()
    }
}

/// Grosse Karte zuoberst: Periode, Restbetrag, Tagesbudget.
private struct RestCard: View {
    let period: BudgetPeriod
    let summary: BudgetSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("\(period.title()) · \(period.rangeText())")
                .font(.subheadline)
                .foregroundStyle(Theme.textSecondary)

            VStack(alignment: .leading, spacing: 2) {
                Text(MoneyFormat.chf(summary.restRappen))
                    .font(.system(size: 46, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(Theme.restColor(isOverdrawn: summary.isOverdrawn))
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
                Text("vo \(MoneyFormat.chf(summary.amountRappen))")
                    .font(.subheadline)
                    .foregroundStyle(Theme.textSecondary)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(restAccessibilityLabel)

            ProgressBar(fraction: summary.spentFraction, isOverdrawn: summary.isOverdrawn)

            DailyLine(summary: summary)
        }
        .card(padding: 20)
    }

    private var restAccessibilityLabel: String {
        if summary.isOverdrawn {
            return "Überzoge um \(MoneyFormat.spoken(-summary.restRappen)), vo \(MoneyFormat.spoken(summary.amountRappen))"
        }
        return "No \(MoneyFormat.spoken(summary.restRappen)) übrig, vo \(MoneyFormat.spoken(summary.amountRappen))"
    }
}

/// „No CHF 42.– pro Tag für 18 Täg" bzw. „Überzoge um CHF 35.–" (SPEC 2.3).
struct DailyLine: View {
    let summary: BudgetSummary

    var body: some View {
        HStack(spacing: 6) {
            if summary.isOverdrawn {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(Theme.negative)
                Text("Überzoge um \(MoneyFormat.chf(-summary.restRappen))")
                    .foregroundStyle(Theme.negative)
            } else if let daily = summary.dailyRappen {
                Image(systemName: "calendar")
                    .foregroundStyle(Theme.accent)
                Text("No \(MoneyFormat.chf(daily)) pro Tag für \(DailyLine.days(summary.remainingDays))")
                    .foregroundStyle(Theme.textPrimary)
            }
        }
        .font(.subheadline.weight(.medium))
        .monospacedDigit()
    }

    static func days(_ count: Int) -> String {
        count == 1 ? "1 Tag" : "\(count) Täg"
    }
}

/// Schmale Anzeige, wie viel vom Betrag schon ausgegeben ist.
struct ProgressBar: View {
    let fraction: Double
    let isOverdrawn: Bool

    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.07))
                Capsule()
                    .fill(isOverdrawn ? Theme.negative : Theme.accent)
                    .frame(width: max(4, geometry.size.width * fraction))
            }
        }
        .frame(height: 6)
        .accessibilityHidden(true)
    }
}
