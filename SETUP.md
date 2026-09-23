# Sackgäud einrichten

Schritt für Schritt von „Projekt heruntergeladen" bis „läuft auf dem iPhone, mit
Widget". Jeder Schritt nennt den genauen Menüpfad. Wenn etwas nicht so aussieht wie
beschrieben, lieber nachfragen als raten.

**Voraussetzungen:** ein Mac mit Xcode 26 oder neuer, ein iPhone mit iOS 26 oder
neuer und die Mitgliedschaft im Apple Developer Program (dieselbe wie für Frostify).

Vieles kennst du von Frostify. **Neu** sind die App Group (Schritt 5) und das Widget
(Schritt 8).

---

## 1. Projekt auf den Mac holen

Zwei gleichwertige Wege – nimm den, bei dem du dich wohler fühlst.

### Weg A: mit Git

Öffne **Terminal** (⌘ + Leertaste, „Terminal" tippen, Enter) und gib ein:

```bash
cd ~/Developer                # derselbe Ordner wie für Frostify
git clone https://github.com/h18e/Sackgaeud.git
cd Sackgaeud
```

Später holst du Änderungen mit:

```bash
cd ~/Developer/Sackgaeud
git pull
```

### Weg B: als ZIP

1. Öffne https://github.com/h18e/Sackgaeud im Browser
2. Grüner Knopf **Code** → **Download ZIP**
3. ZIP in `~/Developer/` entpacken

> **Wichtig:** wie bei Frostify **nicht** in iCloud Drive, Dropbox oder einen
> anderen synchronisierten Ordner legen.

---

## 2. Team-ID eintragen

Im Terminal, im Projektordner:

```bash
cp Config/Signing.local.xcconfig.example Config/Signing.local.xcconfig
open -e Config/Signing.local.xcconfig     # öffnet die Datei in TextEdit
```

Ersetze `ABCDE12345` durch deine Team-ID und sichere mit ⌘S. Es ist dieselbe wie
in `~/Developer/Frostify/Config/Signing.local.xcconfig` – du kannst sie dort
abschreiben:

```bash
cat ~/Developer/Frostify/Config/Signing.local.xcconfig   # zeigt den Inhalt an
```

> Achtung: Die Variable heisst hier `SACKGAEUD_DEVELOPMENT_TEAM`, nicht
> `FROSTIFY_…`. Nur die zehn Zeichen dahinter übernehmen.

---

## 3. Projekt in Xcode öffnen

```bash
open Sackgaeud.xcodeproj
```

Oder im Finder auf `Sackgaeud.xcodeproj` doppelklicken.

---

## 4. Signing der App prüfen

1. Im linken Navigator ganz oben auf das blaue Projektsymbol **Sackgaeud** klicken
2. In der Spalte **TARGETS** auf **Sackgaeud**
3. Reiter **Signing & Capabilities**

| Feld | Erwartet |
|---|---|
| Automatically manage signing | angehakt |
| Team | dein Team (kommt aus Schritt 2) |
| Bundle Identifier | `ch.hebera.sackgaeud` |

Darunter müssen drei Capabilities stehen – sie kommen aus
`Config/Sackgaeud.entitlements`:

- **iCloud** mit angehaktem **CloudKit** und dem Container `iCloud.ch.hebera.sackgaeud`
- **Push Notifications**
- **App Groups** mit `group.ch.hebera.sackgaeud`

Ist der iCloud-Container **rot** oder fehlt er: bei iCloud unter **Containers** auf
**+** klicken und `iCloud.ch.hebera.sackgaeud` eingeben. Xcode legt ihn im
Entwicklerportal an.

---

## 5. App Group anlegen – neu gegenüber Frostify

Über die App Group gibt die App dem Widget den Restbetrag weiter. App **und** Widget
müssen dieselbe Gruppe haben.

1. Noch in **Signing & Capabilities** vom Target **Sackgaeud**, Abschnitt **App Groups**
2. Ist `group.ch.hebera.sackgaeud` **rot** oder nicht angehakt: auf **+** klicken,
   `group.ch.hebera.sackgaeud` eingeben, **OK**. Danach muss der Eintrag angehakt
   und schwarz sein
3. In der Spalte **TARGETS** auf **SackgaeudWidget** wechseln
4. Dort ebenfalls **Signing & Capabilities**: Team muss dasselbe sein, Bundle
   Identifier `ch.hebera.sackgaeud.widget`, und unter **App Groups** muss
   `group.ch.hebera.sackgaeud` angehakt sein

> Ohne App Group läuft die App normal, nur das Widget zeigt „Öffne Sackgäud"
> statt des Betrags.

---

## 6. Erster Start im Simulator

1. Oben in der Leiste das Schema **Sackgaeud** und ein iPhone-Modell wählen
   (z. B. „iPhone 17 Pro")
2. ⌘ + R

Erwartung: „Sali!" und die Frage nach dem Betrag pro Monat. Betrag eingeben →
**Los** → Hauptbildschirm mit dem vollen Betrag und dem Tagesbudget.

Zum Ausprobieren mit mehr Daten: **Zahnrad oben rechts → ganz unten Entwicklung →
Beispiel-Buchungen erzeugen**. Das legt Buchungen über drei Perioden an, damit du
den **Verlauf** (Uhr-Symbol oben links) sehen kannst. Der Abschnitt „Entwicklung"
existiert nur in Debug-Builds.

**Erwartungsmanagement:** Das Projekt wurde ohne Compiler geschrieben (rund 3'000
Zeilen Swift). Es ist gut möglich, dass Xcode beim ersten Bauen ein paar Fehler
meldet. Das ist normal und schnell behoben – schick mir den vollständigen
Fehlertext (siehe Abschnitt 11).

---

## 7. Tests laufen lassen

In Xcode: **⌘ + U**

Geprüft wird die Rechenlogik: Periodenwechsel am 25. um Mitternacht, Jahreswechsel,
Februar, Sommerzeit, verbleibende Tage, Tagesbudget, Überzug, Periodenbetrag nach
einer Änderung, 5-Rappen-Rundung, Eingabe von Beträgen und die Berechnung im Widget.
Alle Tests müssen grün sein.

---

## 8. Widget ausprobieren

Im Simulator oder auf dem iPhone, nachdem die App einmal gelaufen ist:

1. Auf dem Home-Bildschirm lange auf eine freie Stelle drücken, bis die Symbole
   wackeln
2. Oben links **Bearbeiten** → **Widget hinzufügen**
3. **Sackgäud** suchen, die kleine Grösse wählen → **Widget hinzufügen**

Erwartung: Periode, Restbetrag und Tagesbudget. Erfasse in der App eine Ausgabe –
beim Zurückgehen auf den Home-Bildschirm ist der neue Betrag da.

Für den Sperrbildschirm: iPhone sperren, lange auf den Sperrbildschirm drücken →
**Anpassen** → **Sperrbildschirm** → in die Widget-Leiste tippen → **Sackgäud**.

Gegenprobe Sperre: **Einstellungen der App → Mit Face ID sperre** einschalten.
Das Widget zeigt jetzt ein Schloss statt des Betrags.

---

## 9. Auf dem eigenen iPhone starten

1. iPhone per Kabel anschliessen, am iPhone **Vertrauen** bestätigen
2. In Xcode oben das iPhone als Ziel wählen
3. ⌘ + R

Beim allerersten Mal: am iPhone **Einstellungen → Allgemein → VPN & Geräteverwaltung
→ Entwickler-App → deiner Apple-ID vertrauen**.

Am iPhone muss unter **Einstellungen → [dein Name]** iCloud aktiv sein, sonst
gleicht nichts ab. Die App läuft auch ohne – dann einfach nur lokal.

---

## 10. iCloud-Abgleich prüfen

Anders als bei Frostify braucht es keinen Knopf „Schema anlegen": SwiftData legt
die Datenbankstruktur in iCloud beim ersten Sichern selbst an.

1. Auf dem iPhone (nicht im Simulator) eine Ausgabe erfassen
2. Eine Minute warten
3. https://icloud.developer.apple.com/dashboard → Container
   `iCloud.ch.hebera.sackgaeud` → **Schema → Record Types**. Dort müssen
   `CD_Expense`, `CD_SpendingCategory` und `CD_BudgetAmount` stehen

Hast du ein iPad mit derselben Apple-ID: App dort ebenfalls installieren. Nach
kurzer Zeit erscheinen Betrag, Kategorien und Buchungen auch dort, ohne dass nach
dem Betrag gefragt wird.

---

## 11. Wenn etwas schiefgeht

**Bei Build-Fehlern** ist der Issue Navigator in Xcode oft eingeklappt und zeigt nur
die halbe Meldung. Vollständigen Text holen:

```bash
cd ~/Developer/Sackgaeud
xcodebuild -project Sackgaeud.xcodeproj -scheme Sackgaeud -sdk iphonesimulator build > /tmp/build.log 2>&1
grep -E "error:" /tmp/build.log
```

Schick mir die Ausgabe von `grep` – vollständig, nicht als Screenshot.

**Wenn die App einfriert:** Pause-Knopf (⏸) in Xcode, dann **Debug Navigator**
(⌘ + 7) und den Stacktrace des Hauptthreads kopieren.

**Bei Abstürzen:** den vollständigen Text aus dem Konsolenbereich unten in Xcode,
inklusive der Zeile mit `Thread 1:` oder `Fatal error:`.

### Häufige Meldungen

| Meldung | Ursache und Lösung |
|---|---|
| `Signing requires a development team` | Schritt 2 fehlt, die Datei heisst noch `.example`, oder die Variable heisst noch `FROSTIFY_…` |
| `Unable to open base configuration reference file` | `Config/Signing.xcconfig` fehlt – Projekt nochmals sauber holen |
| `Provisioning profile … doesn't include the com.apple.security.application-groups entitlement` | App Group noch nicht angelegt → Schritt 5, bei **beiden** Targets |
| `The bundle identifier of the extension … must be prefixed with the parent app's bundle identifier` | Bundle Identifier des Widgets geändert – er muss `ch.hebera.sackgaeud.widget` bleiben |
| `CFBundleVersion of an app extension … must match that of its containing parent app` | Versions- oder Build-Nummer nur bei einem Target geändert – bei App und Widget gleich setzen |
| `CloudKit integration does not support unique constraints` | Am Modell wurde eine Eindeutigkeitsregel gesetzt – Sackgäud benutzt bewusst keine |
| `Unable to initialize without an iCloud account (CKAccountStatusNoAccount)` | **Kein Fehler der App.** Der Simulator ist nicht bei iCloud angemeldet; die App läuft lokal weiter |
| `BUG IN CLIENT OF CLOUDKIT: … require the 'remote-notification' background mode` | Der Schlüssel fehlt in `Config/Info.plist` – als `INFOPLIST_KEY_*`-Einstellung wird er stillschweigend verworfen |
| `iCloud-Datenbank nicht verfügbar, lokal weiter` in der Konsole | iCloud ist für diesen Build nicht eingerichtet (meist Schritt 4). Die App läuft, gleicht aber nicht ab |
| Widget zeigt „Öffne Sackgäud" | App seit der Installation noch nie geöffnet, oder App Group fehlt (Schritt 5) |
| Widget zeigt einen alten Betrag | Die Buchung kam von einem anderen Gerät; einmal die App öffnen (siehe RELEASE.md, bekannte Grenzen) |
| Im Simulator lässt sich nichts eintippen | Die Bildschirmtastatur des Simulators ist aus: **I/O → Keyboard → Toggle Software Keyboard** (⌘K) |
| Face ID im Simulator | **Features → Face ID → Enrolled** anhaken, dann beim Dialog **Features → Face ID → Matching Face** |
| `The file "Sackgaeud.xcodeproj" couldn't be opened` | Xcode zu alt – es braucht Xcode 26 oder neuer |

---

## 12. Git-Arbeitsweise

Wie bei Frostify: Du musst nichts committen – das mache ich in der Session. Dein
einziger Befehl ist:

```bash
cd ~/Developer/Sackgaeud
git pull
```

Meldet `git pull`, lokale Änderungen würden überschrieben, betrifft das praktisch
immer `Sackgaeud.xcodeproj/project.pbxproj`, weil Xcode sie beim Öffnen umformatiert.
Erst sichern und mir schicken, dann verwerfen:

```bash
git diff Sackgaeud.xcodeproj/project.pbxproj > ~/Desktop/sackgaeud-local.diff
git checkout -- Sackgaeud.xcodeproj/project.pbxproj
git pull
```

Deine Team-ID landet dabei **nie** im Git: Sie steht in
`Config/Signing.local.xcconfig`, die in `.gitignore` eingetragen ist.
