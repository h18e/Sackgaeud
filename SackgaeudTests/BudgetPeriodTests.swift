import Foundation
import Testing
@testable import Sackgaeud

@Suite("Periode vom 25. bis 24.")
struct BudgetPeriodTests {
    let calendar = TestCalendar.zurich

    @Test("Am 25. beginnt die neue Periode")
    func startsOnThe25th() {
        let period = BudgetPeriod(containing: TestCalendar.date(2026, 9, 25), calendar: calendar)
        #expect(period.key == 202609)
        #expect(period.start == TestCalendar.date(2026, 9, 25, hour: 0))
        #expect(period.end == TestCalendar.date(2026, 10, 25, hour: 0))
    }

    @Test("Am 24. kurz vor Mitternacht gehört man noch zur alten Periode")
    func lastMinuteOfThe24th() {
        let period = BudgetPeriod(containing: TestCalendar.date(2026, 10, 24, hour: 23, minute: 59), calendar: calendar)
        #expect(period.key == 202609)
    }

    @Test("Um Mitternacht auf den 25. wechselt die Periode")
    func midnightSwitch() {
        let period = BudgetPeriod(containing: TestCalendar.date(2026, 10, 25, hour: 0), calendar: calendar)
        #expect(period.key == 202610)
    }

    @Test("Anfang Monat gehört zur Periode, die im Vormonat begann")
    func earlyInMonth() {
        let period = BudgetPeriod(containing: TestCalendar.date(2026, 10, 3), calendar: calendar)
        #expect(period.key == 202609)
    }

    @Test("Jahreswechsel: 10. Januar gehört zur Periode ab 25. Dezember")
    func yearBoundary() {
        let period = BudgetPeriod(containing: TestCalendar.date(2027, 1, 10), calendar: calendar)
        #expect(period.key == 202612)
        #expect(period.next(calendar: calendar).key == 202701)
        #expect(period.previous(calendar: calendar).key == 202611)
    }

    @Test("Periode über den Februar hat 28 bzw. 29 Tage")
    func februaryLength() {
        #expect(BudgetPeriod(year: 2027, month: 1, calendar: calendar).dayCount(calendar: calendar) == 31)
        #expect(BudgetPeriod(year: 2027, month: 2, calendar: calendar).dayCount(calendar: calendar) == 28)
        #expect(BudgetPeriod(year: 2028, month: 2, calendar: calendar).dayCount(calendar: calendar) == 29)
    }

    @Test("Periode über die Sommerzeit-Umstellung zählt ganze Tage")
    func daylightSaving() {
        // 25.03.–24.04.2027, Umstellung am 28.03.
        let period = BudgetPeriod(year: 2027, month: 3, calendar: calendar)
        #expect(period.dayCount(calendar: calendar) == 31)
        #expect(period.remainingDays(from: TestCalendar.date(2027, 3, 25), calendar: calendar) == 31)
    }

    @Test("Verbleibende Tage zählen heute mit")
    func remainingDays() {
        let period = BudgetPeriod(year: 2026, month: 9, calendar: calendar)
        #expect(period.remainingDays(from: TestCalendar.date(2026, 9, 25), calendar: calendar) == 30)
        #expect(period.remainingDays(from: TestCalendar.date(2026, 10, 7), calendar: calendar) == 18)
        #expect(period.remainingDays(from: TestCalendar.date(2026, 10, 24, hour: 23), calendar: calendar) == 1)
        #expect(period.remainingDays(from: TestCalendar.date(2026, 10, 25), calendar: calendar) == 0)
        #expect(period.remainingDays(from: TestCalendar.date(2026, 9, 1), calendar: calendar) == 30)
    }

    @Test("Name nach dem Monat, in dem die Periode endet")
    func title() {
        let period = BudgetPeriod(year: 2026, month: 9, calendar: calendar)
        #expect(period.title(calendar: calendar) == "Oktober 2026")
        #expect(period.rangeText(calendar: calendar) == "25.09.–24.10.")
        #expect(BudgetPeriod(year: 2026, month: 12, calendar: calendar).title(calendar: calendar) == "Januar 2027")
    }

    @Test("Schlüssel hin und zurück")
    func keyRoundTrip() {
        let period = BudgetPeriod(key: 202611, calendar: calendar)
        #expect(period == BudgetPeriod(containing: TestCalendar.date(2026, 12, 1), calendar: calendar))
        #expect(period.contains(TestCalendar.date(2026, 11, 25, hour: 0)))
        #expect(!period.contains(TestCalendar.date(2026, 12, 25, hour: 0)))
    }
}
