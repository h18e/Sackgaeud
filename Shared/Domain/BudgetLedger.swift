import Foundation

/// Beträge, Ausgaben und Defizite über mehrere Perioden – für Hauptbildschirm und
/// Verlauf. Reine Logik ohne SwiftData.
struct BudgetLedger {
    let settings: [AmountSetting]
    let spentByPeriod: [Int: Int]
    let calendar: Calendar

    init(settings: [AmountSetting], expenses: [(date: Date, rappen: Int)], calendar: Calendar = .current) {
        self.settings = settings
        self.calendar = calendar
        var spent: [Int: Int] = [:]
        for expense in expenses {
            spent[BudgetPeriod(containing: expense.date, calendar: calendar).key, default: 0] += expense.rappen
        }
        spentByPeriod = spent
    }

    func amount(for period: BudgetPeriod) -> Int {
        BudgetMath.amount(for: period, in: settings) ?? 0
    }

    func spent(in period: BudgetPeriod) -> Int {
        spentByPeriod[period.key] ?? 0
    }

    /// Betrag minus Ausgaben: positiv übrig, negativ überzogen.
    func result(of period: BudgetPeriod) -> Int {
        amount(for: period) - spent(in: period)
    }

    func summary(for period: BudgetPeriod, today: Date) -> BudgetSummary {
        BudgetMath.summary(
            for: period,
            amountRappen: amount(for: period),
            spentRappen: spent(in: period),
            today: today,
            calendar: calendar
        )
    }

    /// Offenes Defizit zu Beginn der Periode.
    func deficit(before period: BudgetPeriod) -> Int {
        BudgetMath.deficit(before: period, calendar: calendar) { result(of: $0) }
    }

    /// Verlauf des Defizits im Budgetjahr von `period`: je Periode ab „Januar" bis
    /// `period` das offene Defizit zu ihrem Beginn (für den Graphen, SPEC 2.5).
    func deficitCourse(until period: BudgetPeriod) -> [DeficitPoint] {
        var points: [DeficitPoint] = []
        var current = period.firstOfBudgetYear(calendar: calendar)
        while current <= period {
            points.append(DeficitPoint(period: current, rappen: deficit(before: current)))
            current = current.next(calendar: calendar)
        }
        return points
    }

    /// Offenes Defizit nach Abschluss der Periode (was sie der nächsten mitgibt).
    /// Nach der Periode „Dezember" beginnt das neue Jahr trotzdem bei 0.
    func deficit(after period: BudgetPeriod) -> Int {
        max(0, deficit(before: period) - result(of: period))
    }
}

/// Ein Punkt im Defizit-Graphen: offenes Defizit zu Beginn einer Periode.
struct DeficitPoint: Identifiable, Equatable {
    let period: BudgetPeriod
    let rappen: Int
    var id: Int { period.key }
}
