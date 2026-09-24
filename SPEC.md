# Sackgäud – Spezifikation (Phase 1)

**Stand:** 2026-09-23 · **Status:** freigegeben und umgesetzt (siehe README.md, SETUP.md) · **Autor:** Claude Code für Raphi

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
| Periodenende | **Jede Periode startet frisch** mit dem vollen Betrag. Ein Überzug wird als **Defizit separat** in die Folgeperioden mitgenommen und durch Einsparungen ausgeglichen; Rückstellung auf 0 mit der Periode „Januar" (SPEC 2.5). |
| Erfassung | **Manuell.** Kein Bank-Import. |
| Buchung | **Betrag, Kategorie, Datum** (Vorgabe heute), **optional eine Notiz** (Nachtrag 24.09.2026). **Keine Gutschriften.** |
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
- Zu welcher Periode eine Buchung gehört, bestimmt allein ihr Datum.

### 2.2 Periodenbetrag

- Der Betrag aus den Einstellungen gilt **ab sofort für die laufende Periode**.
- Vergangene Perioden behalten den Betrag, der zu ihrer Zeit galt.
- Umsetzung: Jede Änderung wird als `BudgetAmount` mit dem Schlüssel der laufenden
  Periode gespeichert (mehrere Änderungen in derselben Periode überschreiben
  einander). Der Betrag einer Periode ist der jüngste Eintrag, dessen Periode
  nicht nach der gesuchten liegt. Für Perioden vor dem ersten Eintrag (rückdatierte
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

### 2.5 Defizit (Nachtrag 24.09.2026)

- Der **Restbetrag bleibt die Zahl der laufenden Periode** und startet immer mit dem
  vollen Betrag. Das Defizit steht **separat** darunter.
- Offenes Defizit zu Beginn einer Periode = Defizit der Vorperiode **minus** deren
  Ergebnis (Betrag − Ausgaben). Ein Überzug vergrössert es, was übrig bleibt,
  verkleinert es. Es wird **nie negativ**: Ein Überschuss ohne offenes Defizit ist
  kein Guthaben.
- Beispiel: September −80 → Oktober startet mit 80. Oktober +50 → November 30.
  November −20 → Dezember 50.
- **Budgetjahr:** Periode „Januar" (ab 25.12.) bis Periode „Dezember" (bis 24.12.).
  Mit der Periode „Januar" beginnt das Defizit wieder bei 0.
- Anzeige auf dem Hauptbildschirm (Nachtrag 24.09.2026): **geschwungener
  Flächengraph** mit dem Verlauf des Defizits im laufenden Budgetjahr – je Periode
  ab „Januar" das offene Defizit zu ihrem Beginn. Linie rot, Fläche darunter von
  100 % Deckkraft an der Linie bis 0 % an der x-Achse. Antippen zeigt den Wert einer
  Periode. Erscheint nur, wenn es im laufenden Jahr ein Defizit gab.
- Unter dem Graphen: „Zum Uusglyche: höchschtens CHF X pro Tag bis
  zum 24." mit X = (Rest − Defizit) ÷ verbleibende Tage. Reicht die Periode nicht,
  steht, wie viel auch ohne weitere Ausgaben offen bleibt. In der Periode „Dezember"
  zusätzlich der Hinweis auf die Rückstellung am 25.12.
- Das Widget zeigt das Defizit nicht.

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
| note | String | freiwillige Notiz, leer = keine (Nachtrag 24.09.2026) |

### 3.2 Category (Kategorie)

| Feld | Typ | Bemerkung |
|---|---|---|
| id | UUID | Startset mit **festen UUIDs**, siehe unten |
| name | String | |
| symbol | String | SF-Symbol-Name |
| colorIndex | Int | Platz in der festen Farbpalette des Themes |
| sortOrder | Int | Reihenfolge im Erfassen-Dialog |
| isFallback | Bool | true nur für „Diverses" |
| expenses | [Expense]? | 1:n, Löschregel *nullify* |

**Startset** (anpassbar: umbenennen, Symbol, Farbe, Reihenfolge, löschen, neu):

| Name | Symbol |
|---|---|
| Ässä uswärts | `fork.knife` |
| Snacks | `popcorn` |
| Technik | `laptopcomputer` |
| Hobby | `paintpalette` |
| Shopping | `bag` |
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
| periodKey | Int | Jahr und Monat des Periodenbeginns, z. B. 202609 – eine Zahl statt eines Datums, damit zwei Geräte in verschiedenen Zeitzonen dieselbe Periode meinen |
| amountRappen | Int | |
| updatedAt | Date | |

Treffen nach dem Sync zwei Einträge mit gleichem `periodKey` aufeinander, gilt der
mit dem jüngeren `updatedAt`.

### 3.4 Nicht synchronisiert (pro Gerät, `UserDefaults`)

- zuletzt benutzte Kategorie (Vorauswahl beim Erfassen)
- Face-ID-Sperre an/aus
- Ein eigenes Merkmal „Einstieg abgeschlossen" braucht es nicht: Der Einstieg
  erscheint, solange es keinen `BudgetAmount` gibt. Trifft auf einem zweiten Gerät
  der Betrag per Sync ein, wechselt die App von selbst zum Hauptbildschirm.

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
   Darunter, nur wenn eines offen ist, das **Defizit** (2.5).
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
- Darunter ein freiwilliges **Notizfeld** (bis 3 Zeilen); die Notiz erscheint in
  der Buchungsliste klein unter der Kategorie.
- Datum: Vorgabe **heute**, als kompakter Datumswähler. Zukünftige Daten sind nicht
  möglich *(siehe 9)*; rückdatieren in vergangene Perioden ist erlaubt.
- „Sichere" ist aktiv, sobald ein gültiger Betrag dasteht.
- Liegt das Datum in einer anderen Periode als der laufenden, sagt ein Hinweis im
  Blatt, in welche („Chunnt i September 2026").
- Bearbeiten nutzt dasselbe Blatt, zusätzlich mit „Lösche".

### 4.4 Historie

- Liste der Perioden, neueste zuoberst: das laufende Budgetjahr ab dem Einstieg
  vollständig, frühere Jahre nur mit den Perioden, in denen Buchungen liegen.
- Jede Zeile: Periodenname, Ergebnis („+ CHF 120.– übrig" grün mit Pfeil,
  „− CHF 35.– überzoge" rot mit Pfeil), darunter das Defizit nach dieser Periode.
- **Löschen** (Nachtrag 24.09.2026): nur Perioden aus **früheren Budgetjahren**,
  einzeln per Wischen oder alle zusammen („Früecheri Jahr lösche"). Gelöscht werden
  alle Buchungen dieser Perioden, nach einer Rückfrage mit der Anzahl, ohne
  Rückgängig. So bleibt ein offenes Defizit bis zum 24.12. immer vorhanden.
- Antippen → Periodendetail:
  - Betrag, Ausgaben, Ergebnis, Defizit vorher und nachher – immer sichtbar,
    CHF 0.– grün, ein offenes Defizit rot, „nachher" zusätzlich fett
  - **Balken je Kategorie**, absteigend nach Summe, mit Betrag und Anteil
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
| Balken | eigene SwiftUI-Ansicht, wie in Frostify | im Dark Mode exakt kontrollierbar, kein Chart-Framework nötig |
| Widget | WidgetKit, **Schnappschuss** in der App Group | siehe 6.2 |
| Sperre | LocalAuthentication | |
| Tests | Swift Testing | Perioden-, Betrags- und Rundungslogik |
| Abhängigkeiten | **keine externen Pakete** | wie Frostify |

### Warum hier SwiftData und nicht Core Data wie bei Frostify?

Bei Frostify war CloudKit **Sharing zwischen zwei Apple-IDs** der Grund für Core Data –
genau dort ist SwiftData schwach. Sackgäud teilt nichts; es braucht nur den
Abgleich der privaten Datenbank zwischen Raphis eigenen Geräten. Das deckt SwiftData
direkt ab, mit deutlich weniger Rahmen-Code. Alle schreibenden Zugriffe liegen
in `BudgetRepository`, ein Wechsel bliebe also auf eine Stelle beschränkt.

---

## 6. Architektur

### 6.1 Ordnerstruktur

```
Sackgaeud/                         # nur App
├── App/                           # Einstieg, Wurzelansicht, Sperrbildschirm
├── Model/                         # Expense, SpendingCategory, BudgetAmount, Startset
├── Persistence/
│   ├── ModelContainerFactory.swift  # iCloud-Konfiguration, lokaler Rückfall
│   └── BudgetRepository.swift       # alle schreibenden Zugriffe
├── Services/                      # Face-ID-Sperre, Rückgängig, Widget-Schnappschuss
├── Features/                      # Onboarding, Overview, ExpenseEditor, History, Settings, Shared
└── Resources/
Shared/                            # App und Widget
├── Domain/                        # BudgetPeriod, BudgetMath, MoneyFormat, WidgetSnapshot
└── Design/                        # Theme
SackgaeudWidget/                   # Widget-Erweiterung
SackgaeudTests/
```

Die Kategorie heisst im Code `SpendingCategory`, weil die Objective-C-Laufzeit
den Namen `Category` bereits belegt.

### 6.2 Schichtenregel

- **Views** lesen Listen über `@Query` – so aktualisiert sich die Oberfläche bei
  eintreffenden Sync-Änderungen von selbst.
- **Domain** kennt SwiftData nicht. Alle Rechenregeln aus Kapitel 2 liegen dort und
  werden getestet, insbesondere die Randfälle: 24./25. um Mitternacht, Jahreswechsel,
  Periode über den Februar, Buchung am letzten Tag, Rest genau 0, Überzug.
- **Persistence:** Geschrieben wird nur über `BudgetRepository`.
- **Widget:** Es öffnet die Datenbank **nicht**. Die App legt nach jeder Änderung
  einen Schnappschuss (Periode, Betrag, Ausgaben, Betrag aus den Einstellungen) in
  die App Group; daraus rechnet das Widget Rest und Tagesbudget für jeden Zeitpunkt
  selbst aus, auch über Mitternacht und den 25. hinweg. So laufen nie zwei Prozesse
  gegen denselben iCloud-gespiegelten Speicher.

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
| Gutschriften | nicht vorgesehen |
| Limiten je Kategorie, Übertrag von Überschüssen, Fixkosten | nicht vorgesehen |
| Teilen mit einer zweiten Person | nicht vorgesehen |

---

## 9. Von mir gesetzte Details – bestätigt

Diese Punkte waren im Gespräch nicht ausdrücklich Thema und wurden mit der
Freigabe so bestätigt.

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

## 11. Umsetzung

Freigegeben am 23.09.2026, umgesetzt in dieser Reihenfolge:

1. Xcode-Projekt, Modelle, Domain-Logik + Tests
2. Einstieg, Hauptbildschirm, Erfassen/Bearbeiten
3. Historie mit Periodendetail, Einstellungen, Kategorienverwaltung
4. iCloud-Sync, Face-ID-Sperre
5. Widget
6. `README.md`, `SETUP.md`, `RELEASE.md`, `PRIVACY.md`, `TEXTE.md`

Nächster Schritt: Build und Test in Xcode (SETUP.md).
