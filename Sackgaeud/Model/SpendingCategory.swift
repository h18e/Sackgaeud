import Foundation
import SwiftData

/// Eine Kategorie (SPEC 3.2). Dient nur der Auswertung – keine eigenen Limiten.
///
/// Heisst nicht einfach `Category`, weil die Objective-C-Laufzeit unter diesem Namen
/// bereits einen Typ mitbringt; der Namenskonflikt führt zu verwirrenden
/// Compiler-Meldungen.
@Model
final class SpendingCategory {
    /// Beim Startset feste Werte (siehe `CategorySeed`), sonst zufällig.
    var id: UUID = UUID()
    var name: String = ""
    /// Name eines SF Symbols.
    var symbol: String = "ellipsis.circle"
    /// Platz in `Theme.categoryPalette`.
    var colorIndex: Int = 0
    /// Reihenfolge im Erfassen-Dialog und in den Einstellungen.
    var sortOrder: Int = 0
    /// true nur für „Diverses": nicht löschbar, fängt Buchungen gelöschter Kategorien auf.
    var isFallback: Bool = false

    @Relationship(deleteRule: .nullify, inverse: \Expense.category)
    var expenses: [Expense]? = []

    init(
        id: UUID = UUID(),
        name: String,
        symbol: String,
        colorIndex: Int,
        sortOrder: Int,
        isFallback: Bool = false
    ) {
        self.id = id
        self.name = name
        self.symbol = symbol
        self.colorIndex = colorIndex
        self.sortOrder = sortOrder
        self.isFallback = isFallback
    }

    var expenseCount: Int { expenses?.count ?? 0 }
}
