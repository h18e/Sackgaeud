import Foundation
import Testing
@testable import Sackgaeud

@Suite("Widget rechnet aus dem Schnappschuss")
struct WidgetSnapshotTests {
    let calendar = TestCalendar.zurich
    let snapshot = WidgetSnapshot(periodKey: 202609, amountRappen: 150_000, spentRappen: 90_000, standingAmountRappen: 150_000)

    @Test("Innerhalb der Periode: Ausgaben aus dem Schnappschuss")
    func samePeriod() {
        let result = snapshot.summary(at: TestCalendar.date(2026, 10, 15), calendar: calendar)
        #expect(result.period.key == 202609)
        #expect(result.summary.restRappen == 60_000)
        #expect(result.summary.remainingDays == 10)
        #expect(result.summary.dailyRappen == 6_000)
    }

    @Test("Ab dem 25. startet die neue Periode frisch, ohne Übertrag")
    func nextPeriodStartsFresh() {
        let result = snapshot.summary(at: TestCalendar.date(2026, 10, 25, hour: 0), calendar: calendar)
        #expect(result.period.key == 202610)
        #expect(result.summary.spentRappen == 0)
        #expect(result.summary.restRappen == 150_000)
        #expect(result.summary.remainingDays == 31)
    }
}
