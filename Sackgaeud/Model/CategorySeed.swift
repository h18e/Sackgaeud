import Foundation
import SwiftData

/// Startset der Kategorien und Zusammenführen von Doppeln nach dem Sync (SPEC 3.2).
///
/// Öffnet Raphi die App erstmals auf zwei Geräten, bevor iCloud abgeglichen hat,
/// legen beide das Startset an. Weil jede Startkategorie eine **feste UUID** hat,
/// erkennt die App die Doppel nach dem Sync und führt sie zusammen.
enum CategorySeed {

    struct Template {
        let id: UUID
        let name: String
        let symbol: String
        let colorIndex: Int
        let isFallback: Bool
    }

    /// Feste Kennungen – nie ändern, sonst entstehen auf bestehenden Geräten Doppel.
    static let fallbackID = UUID(uuidString: "5AC6A0D0-0000-4000-8000-000000000006")!

    static let templates: [Template] = [
        Template(id: UUID(uuidString: "5AC6A0D0-0000-4000-8000-000000000001")!,
                 name: "Ässä uswärts", symbol: "fork.knife", colorIndex: 1, isFallback: false),
        Template(id: UUID(uuidString: "5AC6A0D0-0000-4000-8000-000000000002")!,
                 name: "Snacks", symbol: "popcorn", colorIndex: 7, isFallback: false),
        Template(id: UUID(uuidString: "5AC6A0D0-0000-4000-8000-000000000003")!,
                 name: "Technik", symbol: "laptopcomputer", colorIndex: 0, isFallback: false),
        Template(id: UUID(uuidString: "5AC6A0D0-0000-4000-8000-000000000004")!,
                 name: "Hobby", symbol: "paintpalette", colorIndex: 5, isFallback: false),
        Template(id: UUID(uuidString: "5AC6A0D0-0000-4000-8000-000000000005")!,
                 name: "Shopping", symbol: "bag", colorIndex: 6, isFallback: false),
        Template(id: fallbackID,
                 name: "Diverses", symbol: "ellipsis.circle", colorIndex: 3, isFallback: true)
    ]

    /// Erstes Startset (bis 24.09.2026). Kategorien, die noch genau so aussehen,
    /// werden beim Start auf das neue Startset umgestellt – ihre Buchungen wandern mit.
    /// Was du selbst umbenannt hast, bleibt unberührt.
    private static let legacyTemplates: [UUID: (name: String, symbol: String, colorIndex: Int)] = [
        UUID(uuidString: "5AC6A0D0-0000-4000-8000-000000000001")!: ("Ässe", "cart", 2),
        UUID(uuidString: "5AC6A0D0-0000-4000-8000-000000000002")!: ("Uswärts ässe", "fork.knife", 1),
        UUID(uuidString: "5AC6A0D0-0000-4000-8000-000000000003")!: ("Freizyt", "figure.hiking", 0),
        UUID(uuidString: "5AC6A0D0-0000-4000-8000-000000000004")!: ("Ichoufe", "bag", 6),
        UUID(uuidString: "5AC6A0D0-0000-4000-8000-000000000005")!: ("Mobilität", "tram", 5)
    ]

    /// Stellt unveränderte Kategorien des ersten Startsets auf das aktuelle um.
    static func migrateLegacyTemplates(in context: ModelContext) {
        guard let all = try? context.fetch(FetchDescriptor<SpendingCategory>()) else { return }
        var changed = false
        for category in all {
            guard let legacy = legacyTemplates[category.id],
                  legacy.name == category.name,
                  legacy.symbol == category.symbol,
                  legacy.colorIndex == category.colorIndex,
                  let current = templates.first(where: { $0.id == category.id }) else { continue }
            category.name = current.name
            category.symbol = current.symbol
            category.colorIndex = current.colorIndex
            changed = true
        }
        if changed {
            try? context.save()
        }
    }

    /// Legt das Startset an, falls noch gar keine Kategorie existiert.
    static func seedIfNeeded(in context: ModelContext) {
        let count = (try? context.fetchCount(FetchDescriptor<SpendingCategory>())) ?? 0
        guard count == 0 else { return }
        for (index, template) in templates.enumerated() {
            context.insert(SpendingCategory(
                id: template.id,
                name: template.name,
                symbol: template.symbol,
                colorIndex: template.colorIndex,
                sortOrder: index,
                isFallback: template.isFallback
            ))
        }
        try? context.save()
    }

    /// Führt Kategorien mit gleicher UUID zusammen und stellt sicher, dass es genau
    /// eine Auffang-Kategorie „Diverses" gibt.
    ///
    /// Behalten wird pro UUID die Kategorie, die du bearbeitet hast (Name, Symbol oder
    /// Farbe weichen vom Startset ab); sonst die mit mehr Buchungen. Die Buchungen der
    /// anderen werden umgehängt, danach werden die Doppel gelöscht.
    static func mergeDuplicates(in context: ModelContext) {
        guard let all = try? context.fetch(FetchDescriptor<SpendingCategory>()) else { return }
        guard !all.isEmpty else { return }

        let groups = Dictionary(grouping: all, by: \.id)
        var changed = false
        var removed = Set<ObjectIdentifier>()

        for (_, group) in groups where group.count > 1 {
            let keeper = group.max { lhs, rhs in
                rank(lhs) < rank(rhs)
            } ?? group[0]
            for duplicate in group where duplicate !== keeper {
                for expense in duplicate.expenses ?? [] {
                    expense.category = keeper
                }
                context.delete(duplicate)
                removed.insert(ObjectIdentifier(duplicate))
                changed = true
            }
        }

        // Ohne Auffang-Kategorie liesse sich keine Kategorie mehr löschen.
        let remaining = all.filter { !removed.contains(ObjectIdentifier($0)) }
        if !remaining.contains(where: \.isFallback) {
            let template = templates.first { $0.isFallback }!
            context.insert(SpendingCategory(
                id: template.id,
                name: template.name,
                symbol: template.symbol,
                colorIndex: template.colorIndex,
                sortOrder: (remaining.map(\.sortOrder).max() ?? 0) + 1,
                isFallback: true
            ))
            changed = true
        }

        if changed {
            try? context.save()
        }
    }

    /// Je höher, desto eher wird die Kategorie behalten.
    private static func rank(_ category: SpendingCategory) -> Int {
        let edited = templates.first { $0.id == category.id }.map { template in
            template.name != category.name
                || template.symbol != category.symbol
                || template.colorIndex != category.colorIndex
        } ?? false
        return (edited ? 1_000_000 : 0) + category.expenseCount
    }
}
