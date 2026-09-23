import Foundation
import LocalAuthentication
import Observation
import WidgetKit

/// Optionale Sperre mit Face ID (SPEC 4.6). Vorgabe: aus.
///
/// Gesperrt wird beim Start und bei jeder Rückkehr aus dem Hintergrund. Face ID wird
/// dann **einmal** von selbst angefragt; scheitert es, bleibt der Sperrbildschirm mit
/// einem Knopf stehen. Ein automatischer zweiter Versuch würde eine Schleife
/// auslösen: Der Face-ID-Dialog schaltet die App kurz inaktiv und wieder aktiv.
@Observable
final class AppLock {

    private(set) var isEnabled: Bool
    private(set) var isLocked: Bool
    private(set) var isAuthenticating = false
    private var shouldPromptAutomatically: Bool

    init() {
        let enabled = SharedStore.isAppLockEnabled
        isEnabled = enabled
        isLocked = enabled
        shouldPromptAutomatically = enabled
    }

    /// App geht in den Hintergrund.
    func lockIfEnabled() {
        guard isEnabled else { return }
        isLocked = true
        shouldPromptAutomatically = true
    }

    /// App wird aktiv: höchstens einmal von selbst nach Face ID fragen.
    @MainActor
    func promptIfNeeded() async {
        guard isLocked, shouldPromptAutomatically, !isAuthenticating else { return }
        shouldPromptAutomatically = false
        await unlock()
    }

    /// Knopf auf dem Sperrbildschirm.
    @MainActor
    func unlock() async {
        guard isLocked, !isAuthenticating else { return }
        if await authenticate(reason: "Sackgäud entsperre") {
            isLocked = false
        }
    }

    /// Schalter in den Einstellungen. Einschalten verlangt einmal Face ID – so ist
    /// sicher, dass es auf dem Gerät funktioniert, bevor man sich aussperrt.
    @MainActor
    func setEnabled(_ enabled: Bool) async {
        if enabled {
            guard await authenticate(reason: "Sperre mit Face ID ischaute") else { return }
        }
        isEnabled = enabled
        isLocked = false
        SharedStore.defaults.set(enabled, forKey: SharedStore.appLockKey)
        // Das Widget zeigt bei aktiver Sperre ein Schloss statt des Betrags.
        WidgetCenter.shared.reloadTimelines(ofKind: SharedStore.widgetKind)
    }

    /// Face ID, Touch ID oder als Rückfall der Gerätecode.
    @MainActor
    private func authenticate(reason: String) async -> Bool {
        isAuthenticating = true
        defer { isAuthenticating = false }
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            return false
        }
        do {
            return try await context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason)
        } catch {
            return false
        }
    }
}
