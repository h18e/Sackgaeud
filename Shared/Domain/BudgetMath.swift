import Foundation

/// Ein gespeicherter Periodenbetrag, losgelöst von SwiftData.
struct AmountSetting: Equatable {
    /// Schlüssel der Periode, ab der der Betrag gilt (siehe `BudgetPeriod.key`).
    let periodKey: Int
    let amountRappen: Int
    let updatedAt: Date
}

/// Kennzahlen einer Periode, wie sie der Hauptbildschirm, die Historie und das
/// Widget zeigen. Alle Beträge in ganzen Rappen, ungerundet.
struct BudgetSummary: Equatable {
    let amountRappen: Int
    let spentRappen: Int
    /// Verbleibende Tage, heute eingeschlossen. 0 für abgeschlossene Perioden.
    let remainingDays: Int

    /// Periodenbetrag minus Ausgaben. Negativ bei Überzug.
    var restRappen: Int { amountRappen - spentRappen }

    var isOverdrawn: Bool { restRappen < 0 }

    /// Tagesbudget: Rest geteilt durch die verbleibenden Tage.
    ///
    /// `nil`, wenn überzogen (dann zeigt die App stattdessen den Überzug) oder die
    /// Periode vorbei ist. Abgerundet auf ganze Rappen – lieber einen Rappen zu
    /// wenig versprechen als zu viel.
    var dailyRappen: Int? {
        guard !isOverdrawn, remainingDays > 0 else { return nil }
        return restRappen / remainingDays
    }

    /// Anteil der Ausgaben am Betrag, 0…1 (für Balken). Über 1 wird gekappt.
    var spentFraction: Double {
        guard amountRappen > 0 else { return spentRappen > 0 ? 1 : 0 }
        return min(max(Double(spentRappen) / Double(amountRappen), 0), 1)
    }
}

enum BudgetMath {

    /// Der Betrag, der für `period` gilt (SPEC 2.2).
    ///
    /// - Pro Periode zählt nur der zuletzt geänderte Eintrag. Das löst auch den Fall,
    ///   dass zwei Geräte vor dem Sync je einen Eintrag für dieselbe Periode angelegt haben.
    /// - Gilt der jüngste Eintrag, dessen Periode nicht nach `period` liegt.
    /// - Liegt `period` vor dem ersten Eintrag (rückdatierte Buchungen), gilt der erste.
    /// - `nil` nur, wenn es gar keinen Eintrag gibt.
    static func amount(for period: BudgetPeriod, in settings: [AmountSetting]) -> Int? {
        let latestPerPeriod = deduplicated(settings)
        if let match = latestPerPeriod.last(where: { $0.periodKey <= period.key }) {
            return match.amountRappen
        }
        return latestPerPeriod.first?.amountRappen
    }

    /// Pro Periodenschlüssel nur der jüngste Eintrag, aufsteigend nach Periode sortiert.
    static func deduplicated(_ settings: [AmountSetting]) -> [AmountSetting] {
        var byKey: [Int: AmountSetting] = [:]
        for setting in settings {
            if let existing = byKey[setting.periodKey], existing.updatedAt >= setting.updatedAt {
                continue
            }
            byKey[setting.periodKey] = setting
        }
        return byKey.values.sorted { $0.periodKey < $1.periodKey }
    }

    static func summary(
        for period: BudgetPeriod,
        amountRappen: Int,
        spentRappen: Int,
        today: Date,
        calendar: Calendar = .current
    ) -> BudgetSummary {
        BudgetSummary(
            amountRappen: amountRappen,
            spentRappen: spentRappen,
            remainingDays: period.remainingDays(from: today, calendar: calendar)
        )
    }

    /// Offenes Defizit zu Beginn von `period` (SPEC 2.5).
    ///
    /// - Ein Überzug vergrössert das Defizit, was übrig bleibt, verkleinert es.
    /// - Es wird nie negativ: Ein Überschuss ohne offenes Defizit ist kein Guthaben.
    /// - Die Periode „Januar" (ab 25.12.) beginnt immer bei 0.
    ///
    /// `result` liefert für eine abgeschlossene Periode Betrag minus Ausgaben.
    static func deficit(
        before period: BudgetPeriod,
        calendar: Calendar = .current,
        result: (BudgetPeriod) -> Int
    ) -> Int {
        var current = period.firstOfBudgetYear(calendar: calendar)
        var deficit = 0
        while current < period {
            deficit = max(0, deficit - result(current))
            current = current.next(calendar: calendar)
        }
        return deficit
    }

    /// Summe je Kategorie, absteigend nach Betrag (für die Balken im Periodendetail).
    ///
    /// Generisch über den Schlüssel, damit die Logik ohne SwiftData testbar bleibt.
    static func totals<Key: Hashable>(_ items: [(key: Key, rappen: Int)]) -> [KeyedTotal<Key>] {
        var sums: [Key: Int] = [:]
        var order: [Key] = []
        for item in items {
            if sums[item.key] == nil { order.append(item.key) }
            sums[item.key, default: 0] += item.rappen
        }
        return order
            .map { KeyedTotal(key: $0, rappen: sums[$0] ?? 0) }
            .sorted { $0.rappen > $1.rappen }
    }
}

/// Ein offenes Defizit und was es für die laufende Periode heisst (SPEC 2.5).
struct DeficitStatus: Equatable {
    /// Offenes Defizit aus früheren Perioden dieses Budgetjahrs.
    let deficitRappen: Int
    let summary: BudgetSummary

    /// Was bis zum 24. übrig bleiben darf, wenn das Defizit ganz ausgeglichen werden
    /// soll. Negativ: Diese Periode reicht nicht für den ganzen Ausgleich.
    var spendableAfterCompensation: Int { summary.restRappen - deficitRappen }

    /// Tagesbudget, wenn das Defizit bis Periodenende ausgeglichen werden soll.
    var dailyWithCompensation: Int? {
        guard spendableAfterCompensation >= 0, summary.remainingDays > 0 else { return nil }
        return spendableAfterCompensation / summary.remainingDays
    }
}

/// Summe für einen Schlüssel, z. B. eine Kategorie.
struct KeyedTotal<Key: Hashable>: Equatable {
    let key: Key
    let rappen: Int
}
