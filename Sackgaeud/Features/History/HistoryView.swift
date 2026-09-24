import SwiftData
import SwiftUI

/// Liste der Perioden mit Ergebnis, neueste zuoberst (SPEC 4.4).
///
/// Das laufende Budgetjahr (Periode „Januar" bis heute) erscheint ab dem Einstieg
/// vollständig. Frühere Jahre nur mit den Perioden, in denen Buchungen liegen – und
/// nur diese lassen sich löschen, einzeln oder alle zusammen. So bleibt ein offenes
/// Defizit bis zum 24.12. immer sichtbar (SPEC 2.5).
struct HistoryView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.today) private var today
    @Query private var amounts: [BudgetAmount]
    @Query private var expenses: [Expense]

    @State private var pendingDeletion: [BudgetPeriod] = []

    private var current: BudgetPeriod { BudgetPeriod(containing: today) }

    private var ledger: BudgetLedger {
        BudgetLedger(
            settings: amounts.map(\.setting),
            expenses: expenses.map { (date: $0.date, rappen: $0.amountRappen) }
        )
    }

    private var rows: [HistoryRow] {
        let current = self.current
        let ledger = self.ledger
        let firstKey = amounts.map(\.periodKey).min() ?? current.key

        var keys = Set(ledger.spentByPeriod.keys.filter { $0 <= current.key })
        var period = current
        let yearStart = current.firstOfBudgetYear()
        while period >= yearStart && period.key >= firstKey {
            keys.insert(period.key)
            period = period.previous()
        }

        return keys.sorted(by: >).map { key in
            let period = BudgetPeriod(key: key)
            return HistoryRow(
                period: period,
                summary: ledger.summary(for: period, today: today),
                isCurrent: key == current.key,
                deficitAfter: key == current.key ? 0 : ledger.deficit(after: period),
                isDeletable: period.budgetYear < current.budgetYear
            )
        }
    }

    private var deletableRows: [HistoryRow] { rows.filter(\.isDeletable) }

    var body: some View {
        List {
            ForEach(rows) { row in
                NavigationLink {
                    PeriodDetailView(period: row.period)
                } label: {
                    HistoryRowView(row: row)
                }
                .listRowBackground(Theme.surface)
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    if row.isDeletable {
                        Button(role: .destructive) {
                            pendingDeletion = [row.period]
                        } label: {
                            Label("Lösche", systemImage: "trash")
                        }
                        .tint(Theme.negative)
                    }
                }
            }

            Section {
                EmptyView()
            } footer: {
                Text("Lösche chasch nume Periode us früechere Jahr – so blybt es offes Defizit bis zum 24.12. geng sichtbar.")
            }
        }
        .listStyle(.insetGrouped)
        .themedList()
        .navigationTitle("Verlouf")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(role: .destructive) {
                    pendingDeletion = deletableRows.map(\.period)
                } label: {
                    Label("Früecheri Jahr lösche", systemImage: "trash")
                }
                .tint(Theme.negative)
                .disabled(deletableRows.isEmpty)
            }
        }
        .confirmationDialog(
            deletionTitle,
            isPresented: Binding(
                get: { !pendingDeletion.isEmpty },
                set: { if !$0 { pendingDeletion = [] } }
            ),
            titleVisibility: .visible
        ) {
            Button("Lösche", role: .destructive) {
                BudgetRepository(context: context).deleteExpenses(in: pendingDeletion)
                pendingDeletion = []
            }
            Button("Abbräche", role: .cancel) {
                pendingDeletion = []
            }
        } message: {
            Text("Das cha nid rückgängig gmacht wärde.")
        }
    }

    private var deletionTitle: String {
        let count = pendingDeletion.reduce(0) { $0 + expenseCount(in: $1) }
        let bookings = count == 1 ? "1 Buechig" : "\(count) Buechige"
        if pendingDeletion.count == 1, let period = pendingDeletion.first {
            return "\(period.title()) lösche? (\(bookings))"
        }
        return "\(pendingDeletion.count) Periode lösche? (\(bookings))"
    }

    private func expenseCount(in period: BudgetPeriod) -> Int {
        expenses.filter { period.contains($0.date) }.count
    }
}

struct HistoryRow: Identifiable {
    let period: BudgetPeriod
    let summary: BudgetSummary
    let isCurrent: Bool
    /// Offenes Defizit nach dieser Periode (0 für die laufende).
    let deficitAfter: Int
    /// Nur Perioden aus früheren Budgetjahren.
    let isDeletable: Bool
    var id: Int { period.key }
}

private struct HistoryRowView: View {
    let row: HistoryRow

    private var deficitText: String {
        let amount = MoneyFormat.chf(row.deficitAfter)
        return row.period.next().startsBudgetYear ? "Defizit \(amount) · am 25.12. zrüggsetzt" : "Defizit \(amount)"
    }

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(row.period.title())
                    .foregroundStyle(Theme.textPrimary)
                Text(row.isCurrent ? "\(row.period.rangeText()) · louft no" : row.period.rangeText())
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
                if row.deficitAfter > 0 {
                    Text(deficitText)
                        .font(.caption)
                        .monospacedDigit()
                        .foregroundStyle(Theme.negative)
                }
            }
            Spacer(minLength: 8)
            ResultLabel(summary: row.summary, isCurrent: row.isCurrent)
        }
        .padding(.vertical, 2)
    }
}

/// Ergebnis einer Periode: „+ CHF 120.– übrig" oder „− CHF 35.– überzoge", immer mit
/// Pfeil und Text – nie nur über die Farbe.
struct ResultLabel: View {
    let summary: BudgetSummary
    var isCurrent = false

    var body: some View {
        VStack(alignment: .trailing, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: summary.isOverdrawn ? "arrow.down.right" : "arrow.up.right")
                Text(amountText)
                    .monospacedDigit()
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(summary.isOverdrawn ? Theme.negative : Theme.accent)
            Text(summary.isOverdrawn ? "überzoge" : (isCurrent ? "no übrig" : "übrig"))
                .font(.caption)
                .foregroundStyle(Theme.textSecondary)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(spokenText)
    }

    private var amountText: String {
        let rest = summary.restRappen
        return summary.isOverdrawn ? "\u{2212} \(MoneyFormat.chf(-rest))" : "+ \(MoneyFormat.chf(rest))"
    }

    private var spokenText: String {
        let rest = summary.restRappen
        return summary.isOverdrawn ? "Überzoge um \(MoneyFormat.spoken(-rest))" : "\(MoneyFormat.spoken(rest)) übrig"
    }
}
