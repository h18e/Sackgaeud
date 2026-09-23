import SwiftData
import SwiftUI

/// Liste der Perioden mit Ergebnis, neueste zuoberst (SPEC 4.4).
///
/// Gezeigt wird ab der Periode des Einstiegs (erster gespeicherter Betrag) bis zur
/// laufenden. Ältere Perioden erscheinen nur, wenn rückdatierte Buchungen darin liegen.
struct HistoryView: View {
    @Environment(\.today) private var today
    @Query private var amounts: [BudgetAmount]
    @Query private var expenses: [Expense]

    private var rows: [HistoryRow] {
        let current = BudgetPeriod(containing: today)
        let settings = amounts.map(\.setting)

        var spentByPeriod: [Int: Int] = [:]
        for expense in expenses {
            spentByPeriod[BudgetPeriod(containing: expense.date).key, default: 0] += expense.amountRappen
        }

        let firstKey = settings.map(\.periodKey).min() ?? current.key
        var keys = Set(spentByPeriod.keys.filter { $0 <= current.key })
        var period = current
        var guardCount = 0
        // Obergrenze nur als Schutz gegen eine Endlosschleife bei kaputten Daten.
        while period.key >= firstKey && guardCount < 1200 {
            keys.insert(period.key)
            period = period.previous()
            guardCount += 1
        }

        return keys.sorted(by: >).map { key in
            let period = BudgetPeriod(key: key)
            let summary = BudgetMath.summary(
                for: period,
                amountRappen: BudgetMath.amount(for: period, in: settings) ?? 0,
                spentRappen: spentByPeriod[key] ?? 0,
                today: today
            )
            return HistoryRow(period: period, summary: summary, isCurrent: key == current.key)
        }
    }

    var body: some View {
        List {
            ForEach(rows) { row in
                NavigationLink {
                    PeriodDetailView(period: row.period)
                } label: {
                    HistoryRowView(row: row)
                }
                .listRowBackground(Theme.surface)
            }
        }
        .listStyle(.insetGrouped)
        .themedList()
        .navigationTitle("Verlouf")
    }
}

struct HistoryRow: Identifiable {
    let period: BudgetPeriod
    let summary: BudgetSummary
    let isCurrent: Bool
    var id: Int { period.key }
}

private struct HistoryRowView: View {
    let row: HistoryRow

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(row.period.title())
                    .foregroundStyle(Theme.textPrimary)
                Text(row.isCurrent ? "\(row.period.rangeText()) · louft no" : row.period.rangeText())
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
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
