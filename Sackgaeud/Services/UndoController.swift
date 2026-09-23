import Foundation
import Observation

/// „Rückgängig" nach dem Löschen einer Buchung (SPEC 9, Punkt 5).
///
/// Gelöscht wird ohne Rückfrage; dafür steht ein paar Sekunden lang ein Hinweis mit
/// „Rückgängig" unten am Bildschirm. Liegt an der Wurzel der App, damit der Hinweis
/// auch nach dem Schliessen des Bearbeiten-Blatts sichtbar bleibt.
@Observable
final class UndoController {

    private(set) var pending: DeletedExpense?
    private var hideTask: Task<Void, Never>?

    /// Wie lange der Hinweis stehen bleibt.
    static let duration: Duration = .seconds(5)

    @MainActor
    func offer(_ deleted: DeletedExpense) {
        pending = deleted
        hideTask?.cancel()
        hideTask = Task { @MainActor [weak self] in
            try? await Task.sleep(for: Self.duration)
            guard !Task.isCancelled else { return }
            self?.pending = nil
        }
    }

    @MainActor
    func undo(using repository: BudgetRepository) {
        guard let pending else { return }
        repository.restore(pending)
        dismiss()
    }

    @MainActor
    func dismiss() {
        hideTask?.cancel()
        pending = nil
    }
}
