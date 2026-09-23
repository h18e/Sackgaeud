import Foundation
import OSLog
import SwiftData

/// Erzeugt die Datenbank der App (SPEC 5).
///
/// SwiftData mit Abgleich über Raphis **private** iCloud-Datenbank. Kein Teilen
/// mit einer zweiten Person – deshalb reicht hier SwiftData, anders als bei Frostify.
enum ModelContainerFactory {

    static let schema = Schema([Expense.self, SpendingCategory.self, BudgetAmount.self])

    /// Muss mit dem Eintrag in `Config/Sackgaeud.entitlements` übereinstimmen.
    static let cloudKitContainer = "iCloud.ch.hebera.sackgaeud"

    private static let logger = Logger(subsystem: "ch.hebera.sackgaeud", category: "Persistence")

    /// Datenbank mit iCloud-Sync. Scheitert das (z. B. weil im Simulator ohne Team
    /// signiert wurde), läuft die App rein lokal weiter statt abzustürzen. Ohne
    /// iCloud-Anmeldung arbeitet SwiftData ohnehin lokal und gleicht später ab.
    static func make() -> ModelContainer {
        // groupContainer: .none – die Datenbank bleibt im Container der App. Ohne diese
        // Angabe legt SwiftData sie in die App Group, sobald es eine gibt; das Widget
        // braucht sie dort aber nicht (es liest nur den Schnappschuss).
        let cloud = ModelConfiguration(
            "Sackgaeud",
            schema: schema,
            groupContainer: .none,
            cloudKitDatabase: .private(cloudKitContainer)
        )
        do {
            return try ModelContainer(for: schema, configurations: cloud)
        } catch {
            logger.error("iCloud-Datenbank nicht verfügbar, lokal weiter: \(error.localizedDescription, privacy: .public)")
        }

        let local = ModelConfiguration("Sackgaeud", schema: schema, groupContainer: .none, cloudKitDatabase: .none)
        do {
            return try ModelContainer(for: schema, configurations: local)
        } catch {
            fatalError("Datenbank konnte nicht geöffnet werden: \(error)")
        }
    }

    /// Datenbank nur im Arbeitsspeicher, für Vorschauen und Tests.
    static func makeInMemory() -> ModelContainer {
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
        do {
            return try ModelContainer(for: schema, configurations: configuration)
        } catch {
            fatalError("Vorschau-Datenbank konnte nicht erzeugt werden: \(error)")
        }
    }
}
