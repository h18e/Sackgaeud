import Foundation

/// Eine Budget-Periode: vom 25. um 00:00 bis vor den nächsten 25. um 00:00.
///
/// Der Stichtag ist bewusst fix und nicht einstellbar (SPEC 1). Er verschiebt sich
/// auch am Wochenende nicht.
///
/// Reine Logik ohne SwiftData – die App, das Widget und die Tests nutzen denselben
/// Code. Der Kalender wird immer mitgegeben, damit die Tests mit fester Zeitzone
/// laufen können.
struct BudgetPeriod: Hashable, Comparable, Identifiable {

    /// Tag im Monat, an dem jede Periode beginnt.
    static let startDay = 25

    /// Beginn, 25. um 00:00 (einschliesslich).
    let start: Date
    /// Ende, nächster 25. um 00:00 (ausschliesslich).
    let end: Date
    /// Jahr und Monat des Periodenbeginns als Zahl, z. B. 202609 für 25.09.–24.10.2026.
    ///
    /// Unter diesem Schlüssel wird der Periodenbetrag gespeichert. Eine Zahl statt eines
    /// Datums, damit zwei Geräte in verschiedenen Zeitzonen dieselbe Periode meinen.
    let key: Int

    var id: Int { key }

    /// Die Periode, in die `date` fällt.
    init(containing date: Date, calendar: Calendar = .current) {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        var year = parts.year ?? 2000
        var month = parts.month ?? 1
        if (parts.day ?? 1) < Self.startDay {
            month -= 1
            if month == 0 {
                month = 12
                year -= 1
            }
        }
        self.init(year: year, month: month, calendar: calendar)
    }

    /// Die Periode mit dem angegebenen Schlüssel (siehe `key`).
    init(key: Int, calendar: Calendar = .current) {
        self.init(year: key / 100, month: key % 100, calendar: calendar)
    }

    /// Die Periode, die am 25. des angegebenen Monats beginnt.
    init(year: Int, month: Int, calendar: Calendar = .current) {
        let startComponents = DateComponents(year: year, month: month, day: Self.startDay)
        let start = calendar.date(from: startComponents) ?? Date(timeIntervalSinceReferenceDate: 0)
        let end = calendar.date(byAdding: .month, value: 1, to: start) ?? start.addingTimeInterval(30 * 86_400)
        self.start = calendar.startOfDay(for: start)
        self.end = calendar.startOfDay(for: end)
        self.key = year * 100 + month
    }

    static func < (lhs: BudgetPeriod, rhs: BudgetPeriod) -> Bool {
        lhs.key < rhs.key
    }

    // MARK: - Nachbarn

    func next(calendar: Calendar = .current) -> BudgetPeriod {
        BudgetPeriod(containing: end, calendar: calendar)
    }

    func previous(calendar: Calendar = .current) -> BudgetPeriod {
        let dayBefore = calendar.date(byAdding: .day, value: -1, to: start) ?? start
        return BudgetPeriod(containing: dayBefore, calendar: calendar)
    }

    // MARK: - Tage

    func contains(_ date: Date) -> Bool {
        date >= start && date < end
    }

    /// Letzter Tag der Periode (der 24.), 00:00.
    func lastDay(calendar: Calendar = .current) -> Date {
        calendar.date(byAdding: .day, value: -1, to: end) ?? end
    }

    /// Anzahl Tage der Periode (28 bis 31).
    func dayCount(calendar: Calendar = .current) -> Int {
        calendar.dateComponents([.day], from: start, to: end).day ?? 30
    }

    /// Verbleibende Tage ab `today`, **heute eingeschlossen** (am 24. also 1).
    ///
    /// Vor Beginn der Periode: alle Tage. Nach ihrem Ende: 0.
    func remainingDays(from today: Date, calendar: Calendar = .current) -> Int {
        let day = calendar.startOfDay(for: today)
        if day < start { return dayCount(calendar: calendar) }
        if day >= end { return 0 }
        return calendar.dateComponents([.day], from: day, to: end).day ?? 0
    }

    // MARK: - Texte

    /// Name der Periode nach dem Monat, in dem sie **endet** – wie beim Lohn:
    /// 25.09.–24.10.2026 heisst „Oktober 2026" (SPEC 2.1).
    func title(calendar: Calendar = .current) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.locale = Locale(identifier: "de_CH")
        formatter.setLocalizedDateFormatFromTemplate("LLLLyyyy")
        return formatter.string(from: lastDay(calendar: calendar))
    }

    /// Zeitraum als „25.09.–24.10.".
    func rangeText(calendar: Calendar = .current) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.dateFormat = "dd.MM."
        return "\(formatter.string(from: start))–\(formatter.string(from: lastDay(calendar: calendar)))"
    }
}
