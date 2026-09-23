import SwiftUI

extension EnvironmentValues {
    /// „Heute" für alle Ansichten. Wird an der Wurzel beim Tageswechsel und beim
    /// Zurückkehren in die App erneuert – so springen Tagesbudget und Periode um
    /// Mitternacht bzw. am 25. um, ohne dass jede Ansicht selbst die Uhr beobachtet.
    @Entry var today: Date = .now
}
