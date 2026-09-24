import Foundation
import SwiftData

/// Alle schreibenden Zugriffe auf die Datenbank (SPEC 6.2).
///
/// Views lesen über `@Query`, damit sie sich bei eintreffenden Sync-Änderungen von
/// selbst erneuern. Geschrieben wird nur hier – so gibt es für jede Regel (z. B.
/// „Buchungen einer gelöschten Kategorie wandern nach Diverses") genau eine Stelle.
struct BudgetRepository {
    let context: ModelContext
    var calendar: Calendar = .current

    // MARK: - Betrag

    /// Setzt den Betrag ab der Periode, in die `today` fällt (SPEC 2.2).
    /// Ein bestehender Eintrag für diese Periode wird überschrieben.
    func setAmount(_ rappen: Int, today: Date = .now) {
        let key = BudgetPeriod(containing: today, calendar: calendar).key
        let descriptor = FetchDescriptor<BudgetAmount>(predicate: #Predicate<BudgetAmount> { $0.periodKey == key })
        let existing = (try? context.fetch(descriptor)) ?? []

        if let first = existing.first {
            first.amountRappen = rappen
            first.updatedAt = .now
            for duplicate in existing.dropFirst() {
                context.delete(duplicate)
            }
        } else {
            context.insert(BudgetAmount(periodKey: key, amountRappen: rappen))
        }
        save()
    }

    // MARK: - Buchungen

    @discardableResult
    func addExpense(amountRappen: Int, date: Date, category: SpendingCategory?) -> Expense {
        let expense = Expense(amountRappen: amountRappen, date: date, category: category, calendar: calendar)
        context.insert(expense)
        save()
        return expense
    }

    func update(_ expense: Expense, amountRappen: Int, date: Date, category: SpendingCategory?) {
        expense.amountRappen = amountRappen
        expense.date = calendar.startOfDay(for: date)
        expense.category = category
        save()
    }

    /// Löscht und liefert die Werte zurück, damit „Rückgängig" die Buchung
    /// wiederherstellen kann.
    func delete(_ expense: Expense) -> DeletedExpense {
        let copy = DeletedExpense(
            id: expense.id,
            amountRappen: expense.amountRappen,
            date: expense.date,
            createdAt: expense.createdAt,
            categoryID: expense.category?.id
        )
        context.delete(expense)
        save()
        return copy
    }

    func restore(_ deleted: DeletedExpense) {
        // Neu nachschlagen: Die Kategorie kann in der Zwischenzeit gelöscht worden sein.
        let restoredCategory = deleted.categoryID.flatMap { self.category(withID: $0) }
        context.insert(Expense(
            id: deleted.id,
            amountRappen: deleted.amountRappen,
            date: deleted.date,
            category: restoredCategory ?? fallbackCategory(),
            createdAt: deleted.createdAt,
            calendar: calendar
        ))
        save()
    }

    /// Löscht alle Buchungen der angegebenen Perioden (Verlauf aufräumen, SPEC 4.4).
    /// Liefert die Anzahl gelöschter Buchungen.
    @discardableResult
    func deleteExpenses(in periods: [BudgetPeriod]) -> Int {
        var count = 0
        for period in periods {
            let start = period.start
            let end = period.end
            let descriptor = FetchDescriptor<Expense>(predicate: #Predicate<Expense> { $0.date >= start && $0.date < end })
            for expense in (try? context.fetch(descriptor)) ?? [] {
                context.delete(expense)
                count += 1
            }
        }
        save()
        return count
    }

    // MARK: - Kategorien

    func fallbackCategory() -> SpendingCategory? {
        let descriptor = FetchDescriptor<SpendingCategory>(predicate: #Predicate<SpendingCategory> { $0.isFallback == true })
        return try? context.fetch(descriptor).first
    }

    func category(withID id: UUID) -> SpendingCategory? {
        let descriptor = FetchDescriptor<SpendingCategory>(predicate: #Predicate<SpendingCategory> { $0.id == id })
        return try? context.fetch(descriptor).first
    }

    func addCategory(name: String, symbol: String, colorIndex: Int) {
        let all = (try? context.fetch(FetchDescriptor<SpendingCategory>())) ?? []
        let nextOrder = (all.map(\.sortOrder).max() ?? -1) + 1
        context.insert(SpendingCategory(name: name, symbol: symbol, colorIndex: colorIndex, sortOrder: nextOrder))
        save()
    }

    func update(_ category: SpendingCategory, name: String, symbol: String, colorIndex: Int) {
        category.name = name
        category.symbol = symbol
        category.colorIndex = colorIndex
        save()
    }

    /// Buchungen wandern nach „Diverses", danach wird die Kategorie gelöscht (SPEC 3.2).
    /// „Diverses" selbst lässt sich nicht löschen.
    func delete(_ category: SpendingCategory) {
        guard !category.isFallback else { return }
        let fallback = fallbackCategory()
        for expense in category.expenses ?? [] {
            expense.category = fallback
        }
        context.delete(category)
        save()
    }

    /// Neue Reihenfolge nach Verschieben in der Liste.
    func reorder(_ categories: [SpendingCategory]) {
        for (index, category) in categories.enumerated() where category.sortOrder != index {
            category.sortOrder = index
        }
        save()
    }

    // MARK: - Einstieg

    /// Erster Start: Betrag für die laufende Periode und Startset anlegen (SPEC 4.1).
    func completeOnboarding(amountRappen: Int, today: Date = .now) {
        CategorySeed.seedIfNeeded(in: context)
        setAmount(amountRappen, today: today)
    }

    private func save() {
        try? context.save()
    }
}

/// Werte einer gelöschten Buchung, für „Rückgängig".
struct DeletedExpense {
    let id: UUID
    let amountRappen: Int
    let date: Date
    let createdAt: Date
    let categoryID: UUID?
}
