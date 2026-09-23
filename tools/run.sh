#!/bin/bash
# Sackgaeud aus dem Terminal bauen, testen und starten – ohne in Xcode zu klicken.
#
#   tools/run.sh build          nur bauen (Simulator)
#   tools/run.sh test           Tests laufen lassen
#   tools/run.sh sim            bauen, Simulator oeffnen, App starten
#   tools/run.sh device         Liste der angeschlossenen iPhones zeigen
#   tools/run.sh device <ID>    bauen, aufs iPhone mit dieser ID installieren, starten
#
# Anderes Simulator-Modell:  SIM="iPhone 16" tools/run.sh sim
# Das vollstaendige Protokoll steht jeweils in /tmp/sackgaeud-build.log.

set -euo pipefail
cd "$(dirname "$0")/.."

SIM="${SIM:-iPhone 17 Pro}"
DERIVED="build"
LOG="/tmp/sackgaeud-build.log"
BUNDLE_ID="ch.hebera.sackgaeud"

usage() {
    sed -n '2,11p' "$0" | sed 's/^# \{0,1\}//'
    exit 1
}

check_signing() {
    if [ ! -f Config/Signing.local.xcconfig ]; then
        echo "❌ Config/Signing.local.xcconfig fehlt – zuerst die Team-ID eintragen (SETUP.md, Abschnitt 2)."
        exit 1
    fi
}

# Fuehrt xcodebuild aus, schreibt alles ins Protokoll und zeigt bei einem Fehler
# nur die Fehlerzeilen – vollstaendig, nicht gekuerzt.
run_xcodebuild() {
    echo "⏳ xcodebuild $* …  (Protokoll: $LOG)"
    if xcodebuild -project Sackgaeud.xcodeproj -scheme Sackgaeud -derivedDataPath "$DERIVED" "$@" > "$LOG" 2>&1; then
        echo "✅ fertig"
    else
        echo "❌ fehlgeschlagen. Die Fehler:"
        echo
        grep -E "error:|✘|Test run with|\*\* .* FAILED \*\*" "$LOG" | sort -u | head -60 || true
        echo
        echo "Bitte diese Zeilen an Claude schicken. Vollstaendig: $LOG"
        exit 1
    fi
}

# UDID des gewuenschten Simulators, z. B. "iPhone 17 Pro".
simulator_udid() {
    xcrun simctl list devices available \
        | grep -m1 -E "^ +$SIM \(" \
        | grep -oE '[0-9A-F]{8}-([0-9A-F]{4}-){3}[0-9A-F]{12}' || true
}

sim_destination() {
    echo "platform=iOS Simulator,name=$SIM"
}

case "${1:-}" in
    build)
        check_signing
        run_xcodebuild -destination "$(sim_destination)" build
        ;;

    test)
        check_signing
        run_xcodebuild -destination "$(sim_destination)" test
        grep -E "Test run with|\*\* TEST" "$LOG" | tail -3 || true
        ;;

    sim)
        check_signing
        UDID="$(simulator_udid)"
        if [ -z "$UDID" ]; then
            echo "❌ Kein Simulator namens \"$SIM\". Vorhanden sind:"
            xcrun simctl list devices available | grep -E "iPhone" || true
            echo "Dann z. B.:  SIM=\"iPhone 16\" tools/run.sh sim"
            exit 1
        fi
        run_xcodebuild -destination "id=$UDID" build
        open -a Simulator
        xcrun simctl boot "$UDID" 2>/dev/null || true   # Fehler heisst nur: laeuft schon
        xcrun simctl bootstatus "$UDID" -b > /dev/null
        xcrun simctl install "$UDID" "$DERIVED/Build/Products/Debug-iphonesimulator/Sackgaeud.app"
        xcrun simctl launch "$UDID" "$BUNDLE_ID"
        echo "✅ Sackgäud laeuft im Simulator ($SIM)."
        ;;

    device)
        check_signing
        DEVICE="${2:-}"
        if [ -z "$DEVICE" ]; then
            echo "Angeschlossene Geraete (die Spalte \"Identifier\" ist die ID):"
            echo
            xcrun devicectl list devices
            echo
            echo "Dann:  tools/run.sh device <Identifier>"
            exit 0
        fi
        # -allowProvisioningUpdates: Xcode darf App-ID, App Group und iCloud-Container
        # im Entwicklerportal selbst anlegen – dafuer muss dein Konto in Xcode
        # angemeldet sein (Xcode → Settings… → Accounts).
        run_xcodebuild -destination "generic/platform=iOS" -allowProvisioningUpdates build
        xcrun devicectl device install app --device "$DEVICE" "$DERIVED/Build/Products/Debug-iphoneos/Sackgaeud.app"
        xcrun devicectl device process launch --device "$DEVICE" "$BUNDLE_ID"
        echo "✅ Sackgäud laeuft auf dem iPhone."
        ;;

    *)
        usage
        ;;
esac
