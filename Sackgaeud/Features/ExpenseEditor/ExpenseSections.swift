import SwiftData
import SwiftUI

/// Was das Erfassen-Blatt öffnet. Eine eigene UUID pro Öffnen, damit `.sheet(item:)`
/// jedes Mal ein frisches Blatt baut – mit festem Schlüssel bekäme man sonst den
/// Zustand vom letzten Mal zurück (derselbe Fehler war in Frostify beim Scannen).
struct ExpenseEditorTarget: Identifiable {
    let id = UUID()
    let expense: Expense?
}

/// Buchungen nach Tag gruppiert, neueste zuoberst. Antippen bearbeitet, nach links
/// wischen löscht – ohne Rückfrage, dafür mit „Rückgängig" (SPEC 4.2).
struct ExpenseSections: View {
    let expenses: [Expense]
    @Binding var editorTarget: ExpenseEditorTarget?

    @Environment(\.modelContext) private var context
    @Environment(\.today) private var today
    @Environment(UndoController.self) private var undo

    private var days: [DayGroup] {
        let grouped = Dictionary(grouping: expenses) { Calendar.current.startOfDay(for: $0.date) }
        return grouped
            .map { DayGroup(day: $0.key, expenses: $0.value.sorted { $0.createdAt > $1.createdAt }) }
            .sorted { $0.day > $1.day }
    }

    var body: some View {
        ForEach(days) { group in
            Section {
                ForEach(group.expenses) { expense in
                    Button {
                        editorTarget = ExpenseEditorTarget(expense: expense)
                    } label: {
                        ExpenseRow(expense: expense)
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(Theme.surface)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            let deleted = BudgetRepository(context: context).delete(expense)
                            undo.offer(deleted)
                        } label: {
                            Label("Lösche", systemImage: "trash")
                        }
                    }
                }
            } header: {
                HStack {
                    Text(DayFormat.dayHeader(group.day, today: today))
                    Spacer()
                    Text(MoneyFormat.chf(group.expenses.reduce(0) { $0 + $1.amountRappen }))
                        .monospacedDigit()
                }
                .foregroundStyle(Theme.textSecondary)
            }
        }
    }
}

/// Buchungen eines Tages.
struct DayGroup: Identifiable {
    let day: Date
    let expenses: [Expense]
    var id: Date { day }
}
