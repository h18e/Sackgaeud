import Foundation
import SwiftData

/// Eine Ausgabe (SPEC 3.1).
///
/// Wegen des iCloud-Syncs haben alle Felder einen Standardwert und die Beziehung ist
/// optional – CloudKit lehnt Pflichtfelder ohne Vorgabe und `unique` ab.
@Model
final class Expense {
    var id: UUID = UUID()
    /// Betrag in ganzen Rappen, immer > 0.
    var amountRappen: Int = 0
    /// Tag der Ausgabe, 00:00 im Gerätekalender. Bestimmt die Periode.
    var date: Date = Date.now
    /// Für die Reihenfolge innerhalb eines Tages.
    var createdAt: Date = Date.now
    /// Fehlt sie (Sync-Randfall), zählt die Buchung als „Diverses".
    var category: SpendingCategory?

    init(
        id: UUID = UUID(),
        amountRappen: Int,
        date: Date,
        category: SpendingCategory?,
        createdAt: Date = .now,
        calendar: Calendar = .current
    ) {
        self.id = id
        self.amountRappen = amountRappen
        self.date = calendar.startOfDay(for: date)
        self.category = category
        self.createdAt = createdAt
    }
}
