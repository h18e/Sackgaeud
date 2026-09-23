import Foundation
import SwiftData

/// Betrag ab einer Periode (SPEC 2.2, 3.3).
///
/// Eine Änderung in den Einstellungen legt einen Eintrag für die laufende Periode an
/// oder überschreibt ihn. Vergangene Perioden behalten so ihren damaligen Betrag.
@Model
final class BudgetAmount {
    /// Schlüssel der Periode, ab der der Betrag gilt, z. B. 202609 (siehe `BudgetPeriod.key`).
    var periodKey: Int = 0
    var amountRappen: Int = 0
    /// Entscheidet, falls nach dem Sync zwei Einträge für dieselbe Periode existieren.
    var updatedAt: Date = Date.now

    init(periodKey: Int, amountRappen: Int, updatedAt: Date = .now) {
        self.periodKey = periodKey
        self.amountRappen = amountRappen
        self.updatedAt = updatedAt
    }

    var setting: AmountSetting {
        AmountSetting(periodKey: periodKey, amountRappen: amountRappen, updatedAt: updatedAt)
    }
}
