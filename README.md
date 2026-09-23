# Sackgäud

Native iOS-App, die eine einzige Frage beantwortet: **Wie viel darf ich bis zum
nächsten 25. noch ausgeben?** Fester Betrag pro Periode minus erfasste Ausgaben –
ohne Fixkosten, ohne Konten, ohne Abo.

- **Spezifikation:** [SPEC.md](SPEC.md)
- **Ersteinrichtung:** [SETUP.md](SETUP.md) ← hier anfangen
- **Vor einer Veröffentlichung:** [RELEASE.md](RELEASE.md)
- **Datenschutz:** [PRIVACY.md](PRIVACY.md)
- **Alle Texte der App:** [TEXTE.md](TEXTE.md) (erzeugt mit `tools/list_texts.py`)

## Überblick

| | |
|---|---|
| Zielsystem | iOS 26 und neuer |
| Oberfläche | SwiftUI |
| Daten & Abgleich | SwiftData mit privater iCloud-Datenbank (nur eigene Geräte) |
| Periode | fix vom 25. bis 24., jede Periode startet frisch |
| Widget | WidgetKit, Home- und Sperrbildschirm, liest einen Schnappschuss aus der App Group |
| Sperre | optional Face ID (LocalAuthentication) |
| Gestaltung | Dark Mode als einziges Erscheinungsbild, Basis aus Frostify, Akzent warmes Grün |
| Abhängigkeiten | keine externen Pakete |

## Aufbau

```
Sackgaeud/                 nur App
├── App/                   Einstieg, Wurzelansicht, Sperrbildschirm, „Heute" im Environment
├── Model/                 SwiftData-Modelle, Startset der Kategorien
├── Persistence/           Datenbank erzeugen, alle schreibenden Zugriffe (BudgetRepository)
├── Services/              Face-ID-Sperre, Rückgängig, Schnappschuss fürs Widget
├── Features/
│   ├── Onboarding/        erster Start: Betrag
│   ├── Overview/          Hauptbildschirm
│   ├── ExpenseEditor/     Erfassen, Bearbeiten, Buchungsliste
│   ├── History/           Perioden und Periodendetail
│   ├── Settings/          Betrag, Kategorien, Face ID
│   └── Shared/            Bausteine (Karten, Balken, Zeilen)
└── Resources/             Asset-Katalog
Shared/                    App **und** Widget
├── Domain/                Periode, Rechenregeln, Rundung, Widget-Schnappschuss
└── Design/                Theme
SackgaeudWidget/           Widget-Erweiterung
SackgaeudTests/            Swift Testing für die Rechenlogik
Config/                    Info.plist, Entitlements, Signierung
tools/                     Strukturprüfung, Textverzeichnis
```

**Warum ein eigener Ordner `Shared/`:** Das Widget ist ein eigenes Target und sieht
nur `Shared/` und `SackgaeudWidget/`. Alles, was beide brauchen – die Rechenregeln
und das Theme –, liegt deshalb dort; SwiftData wird darin bewusst nicht importiert.
`tools/verify_structure.py` prüft, dass das Widget keine App-eigenen Typen verwendet.

## Prüfen ohne Xcode

```bash
python3 tools/verify_structure.py
```

Ersetzt keinen Compiler. Den Build-Nachweis liefert Xcode (⌘B, Tests mit ⌘U).
