import Foundation

/// Was das Widget zum Anzeigen braucht – von der App in die App Group geschrieben.
///
/// Warum ein Schnappschuss statt direkter Datenbankzugriff: Das Widget läuft in
/// einem eigenen Prozess. Würde es die SwiftData-Datenbank selbst öffnen, liefen zwei
/// Prozesse gegen denselben iCloud-gespiegelten Speicher. Drei Zahlen genügen, um
/// Restbetrag und Tagesbudget für jeden Tag bis zum nächsten Öffnen der App korrekt
/// zu berechnen – auch über den Periodenwechsel am 25. hinweg.
struct WidgetSnapshot: Codable, Equatable {
    /// Periode, zu der `spentRappen` gehört.
    var periodKey: Int
    /// Betrag dieser Periode.
    var amountRappen: Int
    /// Ausgaben dieser Periode.
    var spentRappen: Int
    /// Betrag aus den Einstellungen – gilt, sobald eine neue Periode beginnt.
    var standingAmountRappen: Int

    /// Kennzahlen für einen beliebigen Zeitpunkt.
    ///
    /// Liegt `date` in einer späteren Periode als der Schnappschuss, hat die App dort
    /// noch keine Ausgaben gesehen: Die neue Periode beginnt frisch mit dem Betrag aus
    /// den Einstellungen (SPEC 1: kein Übertrag).
    func summary(at date: Date, calendar: Calendar = .current) -> (period: BudgetPeriod, summary: BudgetSummary) {
        let period = BudgetPeriod(containing: date, calendar: calendar)
        let isSamePeriod = period.key == periodKey
        let summary = BudgetMath.summary(
            for: period,
            amountRappen: isSamePeriod ? amountRappen : standingAmountRappen,
            spentRappen: isSamePeriod ? spentRappen : 0,
            today: date,
            calendar: calendar
        )
        return (period, summary)
    }
}

/// Gemeinsamer Speicherort von App und Widget.
enum SharedStore {

    /// App Group, muss in beiden Entitlements-Dateien und im Developer-Portal
    /// identisch eingetragen sein (siehe SETUP.md).
    static let appGroup = "group.ch.hebera.sackgaeud"

    /// Kennung des Widgets, damit die App gezielt dessen Anzeige erneuern kann.
    static let widgetKind = "ch.hebera.sackgaeud.rest"

    private static let snapshotKey = "widgetSnapshot"
    /// Face-ID-Sperre an/aus. Liegt in der App Group, weil das Widget bei aktiver
    /// Sperre keinen Betrag zeigen darf (SPEC 9, Punkt 4).
    static let appLockKey = "appLockEnabled"

    /// Geteilte Einstellungen. Fällt auf die normalen zurück, falls die App Group
    /// (noch) nicht eingerichtet ist – dann sieht das Widget halt nichts.
    static var defaults: UserDefaults {
        UserDefaults(suiteName: appGroup) ?? .standard
    }

    static func loadSnapshot() -> WidgetSnapshot? {
        guard let data = defaults.data(forKey: snapshotKey) else { return nil }
        return try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
    }

    /// Speichert und meldet, ob sich etwas geändert hat.
    @discardableResult
    static func saveSnapshot(_ snapshot: WidgetSnapshot) -> Bool {
        guard loadSnapshot() != snapshot,
              let data = try? JSONEncoder().encode(snapshot) else { return false }
        defaults.set(data, forKey: snapshotKey)
        return true
    }

    static var isAppLockEnabled: Bool {
        defaults.bool(forKey: appLockKey)
    }
}
