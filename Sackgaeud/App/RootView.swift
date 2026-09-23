import Combine
import SwiftData
import SwiftUI

/// Einstieg oder Hauptbildschirm.
///
/// Der Einstieg erscheint, solange es keinen Periodenbetrag gibt. Trifft auf einem
/// zweiten Gerät der Betrag per iCloud ein, wechselt die App von selbst zum
/// Hauptbildschirm – dort wird also nicht nochmals nach dem Betrag gefragt.
struct RootView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase
    @Environment(UndoController.self) private var undo

    @Query private var amounts: [BudgetAmount]
    @Query private var categories: [SpendingCategory]

    @State private var today = Date.now

    var body: some View {
        Group {
            if amounts.isEmpty {
                OnboardingView()
            } else {
                OverviewView()
                    .background(WidgetSnapshotUpdater(today: today))
            }
        }
        .environment(\.today, today)
        .overlay(alignment: .bottom) {
            if let pending = undo.pending {
                UndoBanner(deleted: pending)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 88)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.snappy, value: undo.pending?.id)
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                today = .now
                tidyUp()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged).receive(on: RunLoop.main)) { _ in
            today = .now
        }
        .onChange(of: categories.count) { _, _ in
            tidyUp()
        }
        .onChange(of: amounts.isEmpty) { _, _ in
            tidyUp()
        }
    }

    /// Nach dem Sync: Startset nachholen, falls der Betrag schon da ist, die
    /// Kategorien aber nicht, und Doppel zusammenführen (SPEC 3.2).
    private func tidyUp() {
        guard !amounts.isEmpty else { return }
        CategorySeed.seedIfNeeded(in: context)
        CategorySeed.mergeDuplicates(in: context)
    }
}

/// Hinweis nach dem Löschen einer Buchung.
struct UndoBanner: View {
    let deleted: DeletedExpense
    @Environment(\.modelContext) private var context
    @Environment(UndoController.self) private var undo

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "trash")
                .foregroundStyle(Theme.textSecondary)
            Text("\(MoneyFormat.chf(deleted.amountRappen)) glöscht")
                .foregroundStyle(Theme.textPrimary)
                .monospacedDigit()
            Spacer(minLength: 8)
            Button("Rückgängig") {
                undo.undo(using: BudgetRepository(context: context))
            }
            .fontWeight(.semibold)
            .tint(Theme.accent)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Theme.surfaceElevated, in: Capsule())
        .overlay(Capsule().stroke(Theme.separator, lineWidth: 1))
        .shadow(color: .black.opacity(0.4), radius: 12, y: 4)
    }
}

/// Deckt den Inhalt ab, solange die Face-ID-Sperre aktiv ist (SPEC 4.6).
struct LockScreenView: View {
    @Environment(AppLock.self) private var appLock

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            VStack(spacing: 16) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(Theme.textSecondary)
                Text("Sackgäud isch gsperrt")
                    .font(.headline)
                    .foregroundStyle(Theme.textPrimary)
                if appLock.isLocked && !appLock.isAuthenticating {
                    Button("Entsperre") {
                        Task { await appLock.unlock() }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.accent)
                }
            }
        }
    }
}
