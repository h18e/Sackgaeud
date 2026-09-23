import SwiftData
import SwiftUI

@main
struct SackgaeudApp: App {
    private let container = ModelContainerFactory.make()
    @State private var appLock = AppLock()
    @State private var undo = UndoController()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appLock)
                .environment(undo)
                .overlay {
                    // Auch im App-Umschalter abdecken: Dort ist die App nicht aktiv.
                    if appLock.isLocked || (appLock.isEnabled && scenePhase != .active) {
                        LockScreenView()
                            .environment(appLock)
                    }
                }
                .preferredColorScheme(.dark)
                .tint(Theme.accent)
        }
        .modelContainer(container)
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .background:
                appLock.lockIfEnabled()
            case .active:
                Task { await appLock.promptIfNeeded() }
            default:
                break
            }
        }
    }
}
