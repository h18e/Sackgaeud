import SwiftData
import SwiftUI
import WidgetKit

/// Unsichtbare Ansicht, die den Schnappschuss fürs Widget aktuell hält (SPEC 4.7).
///
/// Sie liest die laufende Periode über `@Query` – damit löst auch eine per iCloud
/// eingetroffene Buchung eine Aktualisierung aus, solange die App offen ist. Das
/// Widget wird nur neu geladen, wenn sich die Zahlen tatsächlich geändert haben.
struct WidgetSnapshotUpdater: View {
    private let period: BudgetPeriod
    @Query private var amounts: [BudgetAmount]
    @Query private var expenses: [Expense]

    init(today: Date) {
        let period = BudgetPeriod(containing: today)
        self.period = period
        let start = period.start
        let end = period.end
        _expenses = Query(filter: #Predicate<Expense> { $0.date >= start && $0.date < end })
    }

    private var snapshot: WidgetSnapshot? {
        guard let amount = BudgetMath.amount(for: period, in: amounts.map(\.setting)) else { return nil }
        return WidgetSnapshot(
            periodKey: period.key,
            amountRappen: amount,
            spentRappen: expenses.reduce(0) { $0 + $1.amountRappen },
            standingAmountRappen: amount
        )
    }

    var body: some View {
        Color.clear
            .frame(width: 0, height: 0)
            .accessibilityHidden(true)
            .task(id: snapshot) {
                guard let snapshot else { return }
                if SharedStore.saveSnapshot(snapshot) {
                    WidgetCenter.shared.reloadTimelines(ofKind: SharedStore.widgetKind)
                }
            }
    }
}
