import Foundation

/// Fester Kalender für alle Tests: gregorianisch, Zürich. So laufen die Tests auf
/// jedem Mac gleich, auch über die Sommerzeit-Umstellung.
enum TestCalendar {
    static let zurich: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Zurich")!
        calendar.locale = Locale(identifier: "de_CH")
        return calendar
    }()

    static func date(_ year: Int, _ month: Int, _ day: Int, hour: Int = 12, minute: Int = 0) -> Date {
        zurich.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
    }
}
