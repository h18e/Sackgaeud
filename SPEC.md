# Sackgäud – Spezifikation (Phase 1)

**Stand:** 2026-09-23 · **Status:** Entwurf zum Gegenlesen · **Autor:** Claude Code für Raphi

Native iOS-App, die eine einzige Frage beantwortet: **Wie viel darf ich bis zum
nächsten 25. noch ausgeben?** Fixkosten, Einnahmen und Konten verwaltet sie bewusst
nicht. Anlass: Die bisherige Budget-App kostet ein Abo; Sackgäud ersetzt sie ohne
laufende Kosten.

---

## 1. Bestätigte Anforderungen

| Thema | Entscheid |
|---|---|
| Budget-Modell | **Restbetrag:** fester Betrag pro Periode minus erfasste Ausgaben. Kategorien dienen nur der Auswertung, sie haben **keine eigenen Limiten**. |
| Fixkosten / Einnahmen | **Nicht in der App.** Der Betrag in den Einstellungen ist bereits das, was nach den Fixkosten frei bleibt. |
| Periode | **Fix vom 25. bis 24.** des Folgemonats, nicht einstellbar, keine Verschiebung bei Wochenenden. |
| Startbetrag | **Ein fester Betrag** in den Einstellungen, gilt automatisch für jede Periode. |
| Periodenende | **Jede Periode startet frisch.** Kein Übertrag von Rest oder Überzug; das Ergebnis steht in der Historie. |
| Erfassung | **Manuell.** Kein Bank-Import. |
| Buchung | **Betrag, Kategorie, Datum** (Vorgabe heute). **Keine Notiz, keine Gutschriften.** |
| Nutzer | **Nur Raphi.** iCloud-Sync zwischen den eigenen Geräten, kein Teilen. |
| Währung | **Nur CHF.** Anzeige auf 5 Rappen gerundet, gespeichert auf den Rappen genau. |
| Widget | **Ja, nur Anzeige** des Restbetrags. Erfassen übers Widget erst in v2. |
| Mitteilungen | **Keine** in v1. |
| Face ID | **Optional**, Vorgabe aus. |
| Sprache | **Berndeutsch**, Du-Form, wie Frostify. |
| Verteilung | Zuerst **TestFlight, nur für Raphi.** Architektur so, dass der App Store später ohne Umbau möglich ist. |
| Mindest-iOS | **iOS 26** |
| Bundle ID | **`ch.hebera.sackgaeud`** (Vorschlag, analog Frostify) |

---

## 2. Begriffe und Rechenregeln

Diese Regeln liegen als reine Funktionen in der Domain-Schicht und bekommen Tests.

### 2.1 Periode

- Eine Periode beginnt am **25. um 00:00** (Kalender und Zeitzone des Geräts) und
  endet vor dem nächsten 25. um 00:00.
- Bezeichnet wird sie nach dem Monat, in dem sie **endet** – so wie der Lohn vom
  25. September „der Oktoberlohn" ist: 25.09.–24.10. heisst **„Oktober 2026"**.
  *(Bitte prüfen, siehe 9.)*
- Zu welcher Periode eine Buchung gehört, bestimmt allein ihr Datum.

### 2.2 Periodenbetrag

- Der Betrag aus den Einstellungen gilt **ab sofort für die laufende Periode**.
- Vergangene Perioden behalten den Betrag, der zu ihrer Zeit galt.
- Umsetzung: Jede Änderung wird als `BudgetAmount` mit dem Startdatum der laufenden
  Periode gespeichert (mehrere Änderungen in derselben Periode überschreiben
  einander). Der Betrag einer Periode ist der jüngste Eintrag, dessen Startdatum
  nicht nach dem Periodenstart liegt. Für Perioden vor dem ersten Eintrag (rückdatierte
  Buchungen) gilt der erste Eintrag.

### 2.3 Restbetrag und Tagesbudget

- **Rest** = Periodenbetrag − Summe aller Buchungen der Periode.
- **Verbleibende Tage** = Tage von heute bis zum letzten Tag der Periode,
  **heute eingeschlossen** (am 24. also 1).
- **Tagesbudget** = Rest ÷ verbleibende Tage. Es bewegt sich also mit jeder Ausgabe
  von heute sofort – „wenn ich das jetzt kaufe, bleibt pro Tag noch so viel".
- **Rest < 0:** Restbetrag rot mit Minus; statt Tagesbudget steht
  „Überzoge um CHF 35.–". Keine Pop-ups, keine Warnungen.
- Farbe ist nie der einzige Träger: Überzug steht immer auch als Text da.

### 2.4 Beträge und Rundung

- Gespeichert als **ganze Rappen (`Int`)** – keine Gleitkommazahlen, keine
  Rundungsfehler beim Aufsummieren.
- Eingabe: Franken mit bis zu zwei Nachkommastellen, grösser als 0, höchstens
  CHF 99'999.95.
- Anzeige: kaufmännisch auf 5 Rappen gerundet, Schweizer Schreibweise
  (`CHF 1'234.55`, ganze Beträge als `CHF 40.–`).
- Summen werden immer aus den ungerundeten Rappen gebildet und erst für die Anzeige
  gerundet.

---

## 3. Datenmodell

Drei Entitäten in SwiftData. Wegen iCloud-Sync gelten die CloudKit-Regeln: alle
Felder optional oder mit Standardwert, keine `unique`-Constraints, alle
Beziehungen optional.

### 3.1 Expense (Buchung)

| Feld | Typ | Bemerkung |
|---|---|---|
| id | UUID | |
| amountRappen | Int | > 0 |
| date | Date | nur der Tag zählt (Mitternacht, Gerätekalender) |
| category | Category? | n:1; fehlt sie (Sync-Randfall), zählt die Buchung als „Diverses" |
| createdAt | Date | für die Reihenfolge innerhalb eines Tages |

### 3.2 Category (Kategorie)

| Feld | Typ | Bemerkung |
|---|---|---|
| id | UUID | Startset mit **festen UUIDs**, siehe unten |
| name | String | |
| symbol | String | SF-Symbol-Name |
| colorKey | String | Schlüssel in die feste Farbpalette des Themes |
| sortOrder | Int | Reihenfolge im Erfassen-Dialog |
| isFallback | Bool | true nur für „Diverses" |
| expenses | [Expense]? | 1:n, Löschregel *nullify* |

**Startset** (anpassbar: umbenennen, Symbol, Farbe, Reihenfolge, löschen, neu):

| Name | Symbol |
|---|---|
| Ässe | `cart` |
| Uswärts ässe | `fork.knife` |
| Freizyt | `figure.hiking` |
| Ichoufe | `bag` |
| Mobilität | `tram` |
| Diverses | `ellipsis.circle` *(nicht löschbar)* |

**Löschen einer Kategorie:** Ihre Buchungen wandern nach „Diverses", danach wird sie
gelöscht. Die Rückfrage nennt die Anzahl betroffener Buchungen.

**Warum feste UUIDs:** Öffnet Raphi die App erstmals auf iPhone und iPad, bevor der
Sync gelaufen ist, legen beide Geräte das Startset an. Mit festen UUIDs erkennt die
App die Doppel nach dem Sync und führt sie zusammen (Buchungen umhängen, Doppel
löschen). Ohne sie gäbe es jede Kategorie zweimal.

### 3.3 BudgetAmount (Betrag ab Periode)

| Feld | Typ | Bemerkung |
|---|---|---|
| periodStart | Date | 25. des Monats, 00:00 |
| amountRappen | Int | |
| updatedAt | Date | |

Treffen nach dem Sync zwei Einträge mit gleichem `periodStart` aufeinander, gilt der
mit dem jüngeren `updatedAt`.

### 3.4 Nicht synchronisiert (pro Gerät, `UserDefaults`)

- zuletzt benutzte Kategorie (Vorauswahl beim Erfassen)
- Face-ID-Sperre an/aus
- Einstieg abgeschlossen ja/nein (wird zusätzlich als erledigt betrachtet, sobald
  per Sync ein `BudgetAmount` eintrifft – auf dem zweiten Gerät fragt die App also
  nicht nochmals nach dem Betrag)

---

## 4. Funktionen

### 4.1 Einstieg (erster Start)

- Ein Bildschirm: „Wie vüu hesch pro Monet zur fryje Verfüegig?" mit Betragsfeld.
- Kurzer Satz dazu: Periode läuft vom 25. bis 24., Fixkosten gehören nicht hinein.
- „Los" legt `BudgetAmount` für die laufende Periode und das Startset an und öffnet
  den Hauptbildschirm.

### 4.2 Hauptbildschirm

Von oben nach unten:

1. **Periodenname** und Zeitraum („Oktober 2026 · 25.09.–24.10.")
2. **Restbetrag** – gross, eine Zahl. Darunter klein „vo CHF 1'500.–".
3. **Tagesbudget** – „No CHF 42.– pro Tag für 18 Tag" bzw. „Überzoge um CHF 35.–".
4. **Letzte Buchungen** der laufenden Periode, nach Tag gruppiert, neueste zuoberst:
   Symbol und Name der Kategorie, Betrag. Antippen → bearbeiten, nach links
   wischen → löschen (ohne Rückfrage, dafür mit einem kurzen „Rückgängig"-Hinweis).
5. **Plus-Knopf** unten, gut mit dem Daumen erreichbar.

Oben rechts: Historie und Einstellungen.

### 4.3 Erfassen und Bearbeiten

Ziel: **unter 5 Sekunden** vom Antippen bis zum Sichern.

- Blatt öffnet sich mit **aktivem Zahlenfeld** (Dezimaltastatur), Kursor bereit.
- Darunter die Kategorien als **Raster antippbarer Kacheln**; die zuletzt benutzte ist
  vorgewählt.
- Datum: Vorgabe **heute**, als kompakter Datumswähler. Zukünftige Daten sind nicht
  möglich *(siehe 9)*; rückdatieren in vergangene Perioden ist erlaubt.
- „Sichere" ist aktiv, sobald ein gültiger Betrag dasteht.
- Liegt das Datum in einer anderen Periode als der laufenden, sagt ein Hinweis im
  Blatt, in welche („Chunnt i September 2026").
- Bearbeiten nutzt dasselbe Blatt, zusätzlich mit „Lösche".

### 4.4 Historie

- Liste aller Perioden **ab der Periode des Einstiegs** bis zur laufenden, neueste
  zuoberst; ältere Perioden erscheinen zusätzlich, wenn rückdatierte Buchungen in
  ihnen liegen.
- Jede Zeile: Periodenname, Ergebnis („+ CHF 120.– übrig" grün mit Pfeil,
  „− CHF 35.– überzoge" rot mit Pfeil).
- Antippen → Periodendetail:
  - Betrag, Ausgaben, Ergebnis
  - **Balken je Kategorie** (Swift Charts), absteigend nach Summe, mit Betrag und Anteil
  - alle Buchungen der Periode, bearbeitbar wie auf dem Hauptbildschirm

### 4.5 Einstellungen

- **Betrag pro Periode** – mit dem Hinweis, dass er ab der laufenden Periode gilt.
- **Kategorie** – Liste, umordnen, bearbeiten, neu, löschen.
- **Face ID** – Schalter, Vorgabe aus.
- **Über** – Version, Datenschutz.

### 4.6 Face-ID-Sperre

- Wenn eingeschaltet: Beim Start und bei jeder Rückkehr aus dem Hintergrund deckt ein
  Sperrbildschirm den Inhalt ab, bis Face ID (oder der Gerätecode als Rückfall)
  erfolgreich ist.
- Im App-Umschalter ist der Inhalt ebenfalls abgedeckt.
- Widget bei aktiver Sperre: siehe 9.

### 4.7 Widget

- **Home-Bildschirm klein** und **Sperrbildschirm** (rechteckig, eine Zeile):
  Restbetrag, bei Platz zusätzlich das Tagesbudget.
- Antippen öffnet die App.
- Aktualisierung: sofort nach jeder Änderung in der App
  (`WidgetCenter.reloadAllTimelines`), zusätzlich planmässig um Mitternacht (neues
  Tagesbudget) und am 25. (neue Periode).
- **Einschränkung:** Eine Buchung, die auf einem *anderen* Gerät erfasst wurde,
  erscheint im Widget erst, wenn die App auf diesem Gerät einmal geöffnet war oder der
  Sync im Hintergrund lief. Bei nur einem iPhone spielt das keine Rolle.

---

## 5. Tech-Stack

| Baustein | Wahl | Begründung |
|---|---|---|
| UI | SwiftUI, **iOS 26+** | wie Frostify |
| Persistenz & Sync | **SwiftData** mit `cloudKitDatabase: .private(…)` | siehe unten |
| Diagramme | Swift Charts | Apple-eigen |
| Widget | WidgetKit, Datenzugriff über **App Group** | Widget und App lesen dieselbe Datenbank |
| Sperre | LocalAuthentication | |
| Tests | Swift Testing | Perioden-, Betrags- und Rundungslogik |
| Abhängigkeiten | **keine externen Pakete** | wie Frostify |

### Warum hier SwiftData und nicht Core Data wie bei Frostify?

Bei Frostify war CloudKit **Sharing zwischen zwei Apple-IDs** der Grund für Core Data –
genau dort ist SwiftData schwach. Sackgäud teilt nichts; es braucht nur den
Abgleich der privaten Datenbank zwischen Raphis eigenen Geräten. Das deckt SwiftData
direkt ab, mit deutlich weniger Rahmen-Code. Auch hier liegt die Persistenz hinter
einem eigenen Protokoll, ein Wechsel bliebe also möglich.

---

## 6. Architektur

### 6.1 Ordnerstruktur

```
Sackgaeud/
├── App/
│   ├── SackgaeudApp.swift         # Einstieg, ModelContainer, Sperre
│   └── RootView.swift             # Einstieg oder Hauptbildschirm
├── Model/                         # SwiftData-Modelle
│   ├── Expense.swift
│   ├── Category.swift
│   ├── BudgetAmount.swift
│   └── CategorySeed.swift         # Startset mit festen UUIDs, Zusammenführen von Doppeln
├── Domain/                        # reine Logik, ohne SwiftData, voll testbar
│   ├── BudgetPeriod.swift         # Periode aus Datum, Name, verbleibende Tage
│   ├── BudgetMath.swift           # Rest, Tagesbudget, Ergebnis, Periodenbetrag
│   └── MoneyFormat.swift          # Rappen ↔ Eingabe, 5-Rappen-Rundung, Anzeige
├── Persistence/
│   ├── ModelContainerFactory.swift  # App Group, CloudKit-Konfiguration
│   └── BudgetRepository.swift       # Protokoll + SwiftData-Umsetzung
├── Features/
│   ├── Onboarding/
│   ├── Overview/                  # Hauptbildschirm
│   ├── ExpenseEditor/             # Erfassen und Bearbeiten
│   ├── History/                   # Perioden und Periodendetail
│   ├── Settings/                  # Betrag, Kategorien, Face ID
│   └── Shared/                    # Theme, Komponenten
├── Services/
│   └── AppLock.swift              # Face-ID-Sperre
└── Resources/
    └── Assets.xcassets
SackgaeudWidget/                   # Widget-Erweiterung
SackgaeudTests/
```

### 6.2 Schichtenregel

- **Views** lesen Listen über `@Query` – so aktualisiert sich die Oberfläche bei
  eintreffenden Sync-Änderungen von selbst.
- **Domain** kennt SwiftData nicht. Alle Rechenregeln aus Kapitel 2 liegen dort und
  werden getestet, insbesondere die Randfälle: 24./25. um Mitternacht, Jahreswechsel,
  Periode über den Februar, Buchung am letzten Tag, Rest genau 0, Überzug.
- **Persistence** kapselt SwiftData hinter `BudgetRepository`; das Widget nutzt
  dieselbe Umsetzung.

### 6.3 Gestaltung und Sprache

- Apple HIG, **Dark Mode als einziges Erscheinungsbild**, Dynamic Type, SF Symbols,
  VoiceOver-Beschriftungen (Beträge werden ausgeschrieben vorgelesen).
- Theme und Komponenten als **Kopie** aus Frostify (`Theme.swift`, `Components.swift`),
  ohne technische Abhängigkeit. **Eigene Akzentfarbe: ein warmes Grün**, damit man
  die Apps auseinanderhält. Weil Grün auch „übrig" bedeutet, ist Überzug rot **und**
  mit Minus und Text – nie nur Farbe.
- Sprache: **Berndeutsch**, dieselben Schreibregeln wie in Frostify
  (L-Vokalisierung, `-ig` statt `-ung`, `nid`/`nüt`/`no`). Die Texte werden wie dort
  in `TEXTE.md` gesammelt.

---

## 7. Datenschutz

- Keine Server, keine Analyse, keine Tracker, keine Netzabfragen ausser Apples
  iCloud-Sync.
- Alle Daten liegen auf dem Gerät und in Raphis privater iCloud-Datenbank.
- Damit ist die App-Store-Angabe später „Keine Daten erfasst" – dieselbe Grundlage
  wie bei Frostify.

---

## 8. Nicht in v1 (bewusst verschoben)

| Punkt | Wann |
|---|---|
| Erfassen per Widget, Kurzbefehle, Siri (App Intents) | v2 |
| CSV-Export als eigenes Backup | v2 |
| Mitteilungen (neue Periode, wenig Rest, Erinnerung) | v2 |
| Trends über mehrere Perioden | v2 |
| Notiz zur Buchung, Gutschriften | nicht vorgesehen |
| Limiten je Kategorie, Übertrag, Fixkosten | nicht vorgesehen |
| Teilen mit einer zweiten Person | nicht vorgesehen |

---

## 9. Von mir gesetzte Details – bitte prüfen

Diese Punkte waren im Gespräch nicht ausdrücklich Thema. Ich habe sie so festgelegt,
wie es mir am sinnvollsten scheint; ein Wort genügt, um sie zu ändern.

| # | Punkt | Vorschlag |
|---|---|---|
| 1 | Name der Periode 25.09.–24.10. | **„Oktober"** (nach dem Monat, in dem sie endet, wie beim Lohn). Alternative: „September". |
| 2 | Tagesbudget | Heute zählt als verbleibender Tag, heutige Ausgaben sind schon abgezogen (2.3). |
| 3 | Zukünftiges Datum bei einer Buchung | **Nicht möglich.** Verhindert Tippfehler, die Geld in der Zukunft „verstecken". |
| 4 | Widget bei aktiver Face-ID-Sperre | Widget zeigt **statt des Betrags ein Schloss**. Sonst liest jeder den Betrag auf dem Sperrbildschirm. |
| 5 | Löschen einer Buchung | **Ohne Rückfrage**, mit „Rückgängig"-Hinweis während einiger Sekunden. |
| 6 | Bundle ID | `ch.hebera.sackgaeud` |
| 7 | App-Icon | Du lieferst es am Schluss (wie bei Frostify), bis dahin ein Platzhalter. |

---

## 10. Ehrliche Einschränkung

Wie bei Frostify: Diese Umgebung ist Linux, ohne macOS und Xcode. Ich schreibe den
Code und prüfe ihn strukturell, kann aber **nicht kompilieren**. Den Build-Nachweis
erbringst du; Compile-Fehler arbeiten wir anhand der exakten Fehlertexte ab.

Neu gegenüber Frostify ist die **Widget-Erweiterung**: Sie braucht in Xcode ein
eigenes Target und eine App Group, die du im Developer-Portal einmal anlegst. Das
kommt Schritt für Schritt ins `SETUP.md`.

---

## 11. Freigabe

Mit „Freigabe", „Umsetzen" oder „Starte jetzt" beginne ich mit Phase 2.
Reihenfolge:

1. Xcode-Projekt, Modelle, Domain-Logik + Tests
2. Einstieg, Hauptbildschirm, Erfassen/Bearbeiten
3. Historie mit Periodendetail, Einstellungen, Kategorienverwaltung
4. iCloud-Sync, Face-ID-Sperre
5. Widget
6. `README.md`, `SETUP.md`, `RELEASE.md`, `PRIVACY.md`, `TEXTE.md`
