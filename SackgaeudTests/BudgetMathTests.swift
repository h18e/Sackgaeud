import Foundation
import Testing
@testable import Sackgaeud

@Suite("Periodenbetrag, Rest und Tagesbudget")
struct BudgetMathTests {
    let calendar = TestCalendar.zurich

    private func setting(_ key: Int, _ rappen: Int, _ minutes: Double = 0) -> AmountSetting {
        AmountSetting(periodKey: key, amountRappen: rappen, updatedAt: Date(timeIntervalSince1970: minutes * 60))
    }

    private func period(_ key: Int) -> BudgetPeriod {
        BudgetPeriod(key: key, calendar: calendar)
    }

    @Test("Ohne Eintrag gibt es keinen Betrag")
    func noSettings() {
        #expect(BudgetMath.amount(for: period(202609), in: []) == nil)
    }

    @Test("Ein Betrag gilt für alle folgenden Perioden")
    func carriesForward() {
        let settings = [setting(202609, 150_000)]
        #expect(BudgetMath.amount(for: period(202609), in: settings) == 150_000)
        #expect(BudgetMath.amount(for: period(202703), in: settings) == 150_000)
    }

    @Test("Vergangene Perioden behalten ihren Betrag")
    func pastKeepsAmount() {
        let settings = [setting(202609, 150_000), setting(202611, 170_000)]
        #expect(BudgetMath.amount(for: period(202610), in: settings) == 150_000)
        #expect(BudgetMath.amount(for: period(202611), in: settings) == 170_000)
        #expect(BudgetMath.amount(for: period(202612), in: settings) == 170_000)
    }

    @Test("Vor dem ersten Eintrag gilt der erste (rückdatierte Buchungen)")
    func beforeFirst() {
        let settings = [setting(202609, 150_000), setting(202611, 170_000)]
        #expect(BudgetMath.amount(for: period(202605), in: settings) == 150_000)
    }

    @Test("Zwei Einträge für dieselbe Periode: der jüngere gewinnt")
    func duplicateAfterSync() {
        let settings = [setting(202609, 150_000, 10), setting(202609, 160_000, 20), setting(202609, 140_000, 5)]
        #expect(BudgetMath.amount(for: period(202609), in: settings) == 160_000)
        #expect(BudgetMath.deduplicated(settings).count == 1)
    }

    @Test("Rest und Tagesbudget, heute mitgezählt")
    func summary() {
        let summary = BudgetMath.summary(
            for: period(202609),
            amountRappen: 150_000,
            spentRappen: 74_400,
            today: TestCalendar.date(2026, 10, 7),
            calendar: calendar
        )
        #expect(summary.restRappen == 75_600)
        #expect(summary.remainingDays == 18)
        #expect(summary.dailyRappen == 4_200)
        #expect(!summary.isOverdrawn)
    }

    @Test("Tagesbudget wird auf ganze Rappen abgerundet")
    func dailyRoundsDown() {
        let summary = BudgetSummary(amountRappen: 10_000, spentRappen: 0, remainingDays: 3)
        #expect(summary.dailyRappen == 3_333)
    }

    @Test("Rest genau 0 ist kein Überzug")
    func exactlyZero() {
        let summary = BudgetSummary(amountRappen: 10_000, spentRappen: 10_000, remainingDays: 5)
        #expect(!summary.isOverdrawn)
        #expect(summary.dailyRappen == 0)
    }

    @Test("Überzug: kein Tagesbudget")
    func overdrawn() {
        let summary = BudgetSummary(amountRappen: 10_000, spentRappen: 13_500, remainingDays: 5)
        #expect(summary.isOverdrawn)
        #expect(summary.restRappen == -3_500)
        #expect(summary.dailyRappen == nil)
        #expect(summary.spentFraction == 1)
    }

    @Test("Abgeschlossene Periode: kein Tagesbudget")
    func closedPeriod() {
        let summary = BudgetSummary(amountRappen: 10_000, spentRappen: 2_000, remainingDays: 0)
        #expect(summary.dailyRappen == nil)
    }

    @Test("Summen je Kategorie, absteigend")
    func totals() {
        let result = BudgetMath.totals([(key: "a", rappen: 500), (key: "b", rappen: 900), (key: "a", rappen: 600)])
        #expect(result.map { $0.key } == ["a", "b"])
        #expect(result.map { $0.rappen } == [1_100, 900])
    }
}
