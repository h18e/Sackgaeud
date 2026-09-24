import Foundation
import Testing
@testable import Sackgaeud

@Suite("Defizit über mehrere Perioden, Rückstellung im Januar")
struct DeficitTests {
    let calendar = TestCalendar.zurich

    private func period(_ key: Int) -> BudgetPeriod {
        BudgetPeriod(key: key, calendar: calendar)
    }

    /// Ergebnisse je Periode (Betrag minus Ausgaben), alles andere 0.
    private func deficit(before key: Int, results: [Int: Int]) -> Int {
        BudgetMath.deficit(before: period(key), calendar: calendar) { results[$0.key] ?? 0 }
    }

    @Test("Budgetjahr: Periode „Januar“ beginnt am 25.12.")
    func budgetYear() {
        #expect(period(202612).budgetYear == 2027)
        #expect(period(202612).startsBudgetYear)
        #expect(period(202611).budgetYear == 2026)
        #expect(period(202701).budgetYear == 2027)
        #expect(period(202609).firstOfBudgetYear(calendar: calendar).key == 202512)
    }

    @Test("Beispiel aus der Absprache: −80, +50, −20")
    func accumulates() {
        // September 2026 = Periode 202608 (25.08.–24.09.)
        let results = [202608: -8_000, 202609: 5_000, 202610: -2_000]
        #expect(deficit(before: 202609, results: results) == 8_000)
        #expect(deficit(before: 202610, results: results) == 3_000)
        #expect(deficit(before: 202611, results: results) == 5_000)
    }

    @Test("Überschuss ohne Defizit ist kein Guthaben")
    func noCredit() {
        let results = [202607: 20_000, 202608: -3_000]
        #expect(deficit(before: 202608, results: results) == 0)
        #expect(deficit(before: 202609, results: results) == 3_000)
    }

    @Test("Überschuss grösser als Defizit: Defizit ist weg, Rest verfällt")
    func overCompensation() {
        let results = [202607: -3_000, 202608: 10_000, 202609: -1_000]
        #expect(deficit(before: 202609, results: results) == 0)
        #expect(deficit(before: 202610, results: results) == 1_000)
    }

    @Test("Periode „Januar“ beginnt bei 0, auch nach Überzug im Dezember")
    func resetInJanuary() {
        let results = [202610: -5_000, 202611: -10_000]
        #expect(deficit(before: 202611, results: results) == 5_000)
        #expect(deficit(before: 202612, results: results) == 0)
        #expect(deficit(before: 202701, results: results) == 0)
    }

    @Test("Ausgleich während der Periode")
    func compensationStatus() {
        let summary = BudgetSummary(amountRappen: 150_000, spentRappen: 30_000, remainingDays: 10)
        let status = DeficitStatus(deficitRappen: 20_000, summary: summary)
        #expect(status.spendableAfterCompensation == 100_000)
        #expect(status.dailyWithCompensation == 10_000)

        let tight = DeficitStatus(deficitRappen: 20_000, summary: BudgetSummary(amountRappen: 150_000, spentRappen: 140_000, remainingDays: 3))
        #expect(tight.spendableAfterCompensation == -10_000)
        #expect(tight.dailyWithCompensation == nil)
    }

    @Test("Ledger rechnet aus Buchungen")
    func ledger() {
        let settings = [AmountSetting(periodKey: 202608, amountRappen: 100_000, updatedAt: .now)]
        let expenses: [(date: Date, rappen: Int)] = [
            (TestCalendar.date(2026, 9, 1), 60_000),
            (TestCalendar.date(2026, 9, 20), 50_000),   // Periode 202608: −10'000
            (TestCalendar.date(2026, 10, 1), 95_000)    // Periode 202609: +5'000
        ]
        let ledger = BudgetLedger(settings: settings, expenses: expenses, calendar: calendar)
        #expect(ledger.result(of: period(202608)) == -10_000)
        #expect(ledger.deficit(after: period(202608)) == 10_000)
        #expect(ledger.deficit(after: period(202609)) == 5_000)
    }
}
