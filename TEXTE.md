# Sackgäud – aui Täxt i dr App

Automatisch us em Quellcode erzeugt mit `tools/list_texts.py`.
Platzhalter wie `\(period.title())` wärde zur Laufzyt dür dr richtig Wärt ersetzt.

Wenn dir öppis nid passt: säg mer d Zile, i ändere's.

---

## Sperre & Rückgängig

`Sackgaeud/App/RootView.swift`

- Zile 76: **\(MoneyFormat.chf(deleted.amountRappen)) glöscht**
- Zile 80: **Rückgängig**
- Zile 105: **Sackgäud isch gsperrt**
- Zile 109: **Entsperre**

## Erschte Start

`Sackgaeud/Features/Onboarding/OnboardingView.swift`

- Zile 20: **Sali!**
- Zile 23: **Sackgäud zeigt dr jederzyt, wie vüu du bis zum nächschte 25. no chasch usgäh.**
- Zile 28: **Wie vüu hesch pro Monet zur fryje Verfüegig?**
- Zile 40: **Betrag pro Monet i Franke**
- Zile 43: **Fixchöschte ghöre nid dry – nume das, wo nachhär für di säuber blibt. E Periode louft geng vom 25. bis zum 24.**
- Zile 52: **Los**

## Hauptbildschirm

`Sackgaeud/Features/Overview/OverviewView.swift`

- Zile 23: **Verlouf**
- Zile 29: **Istellige**
- Zile 42: **Usgab erfasse**
- Zile 107: **No nüt erfasst**
- Zile 108: **Tipp uf „Usgab erfasse“, sobald du öppis zahlt hesch.**
- Zile 139: **vo \(MoneyFormat.chf(summary.amountRappen))**
- Zile 155: **Überzoge um \(MoneyFormat.spoken(-summary.restRappen)), vo \(MoneyFormat.spoken(summary.amountRappen))**
- Zile 157: **No \(MoneyFormat.spoken(summary.restRappen)) übrig, vo \(MoneyFormat.spoken(summary.amountRappen))**
- Zile 170: **Überzoge um \(MoneyFormat.chf(-summary.restRappen))**
- Zile 175: **No \(MoneyFormat.chf(daily)) pro Tag für \(DailyLine.days(summary.remainingDays))**
- Zile 184: **1 Tag**
- Zile 184: **\(count) Täg**

## Usgab erfasse & bearbeite

`Sackgaeud/Features/ExpenseEditor/ExpenseEditorView.swift`

- Zile 63: **Buechig bearbeite**
- Zile 63: **Usgab erfasse**
- Zile 67: **Abbräche**
- Zile 70: **Sichere**
- Zile 98: **Betrag i Franke**
- Zile 130: **Chunnt i \(period.title())**
- Zile 144: **Buechig lösche**

## Buechige-Liste

`Sackgaeud/Features/ExpenseEditor/ExpenseSections.swift`

- Zile 45: **Lösche**

## Verlouf

`Sackgaeud/Features/History/HistoryView.swift`

- Zile 58: **Verlouf**
- Zile 77: **\(row.period.rangeText()) · louft no**
- Zile 103: **überzoge**
- Zile 103: **no übrig**
- Zile 103: **übrig**
- Zile 113: **\u{2212} \(MoneyFormat.chf(-rest))**
- Zile 113: **+ \(MoneyFormat.chf(rest))**
- Zile 118: **Überzoge um \(MoneyFormat.spoken(-rest))**
- Zile 118: **\(MoneyFormat.spoken(rest)) übrig**

## Periode im Detail

`Sackgaeud/Features/History/PeriodDetailView.swift`

- Zile 55: **Usgabe**
- Zile 59: **Ergäbnis**
- Zile 69: **Nach Kategorie**
- Zile 78: **\(Int((Double(entry.rappen) / Double(total) * 100).rounded())) %**
- Zile 88: **Kei Buechige i dere Periode**

## Istellige

`Sackgaeud/Features/Settings/SettingsView.swift`

- Zile 20: **Betrag pro Periode**
- Zile 32: **E Periode louft geng vom 25. bis zum 24.**
- Zile 37: **Mit Face ID sperre**
- Zile 43: **Bim Starte und bim Zrüggcho i d App fragt Sackgäud nach Face ID. S Widget zeigt de es Schloss statt em Betrag.**
- Zile 53: **Dateschutz**
- Zile 55: **Aui Date blibe uf dym Grät und i dyre private iCloud. Kei Server, kei Wärbig, kei Tracking.**
- Zile 70: **Istellige**
- Zile 106: **Betrag pro Periode i Franke**
- Zile 109: **Gilt ab sofort für d laufendi Periode (\(period.title())). Vergangeni Periode bhalte ihre Betrag.**
- Zile 118: **Sichere**

## Istellige → Kategorie

`Sackgaeud/Features/Settings/CategoryListView.swift`

- Zile 28: **Cha nid glöscht wärde**
- Zile 38: **Lösche**
- Zile 46: **„Diverses“ cha nid glöscht wärde: Dert lande d Buechige vo glöschte Kategorie.**
- Zile 63: **Neui Kategorie**
- Zile 82: **Abbräche**
- Zile 96: **Die Kategorie het keni Buechige.**
- Zile 97: **1 Buechig chunnt nach „Diverses“.**
- Zile 98: **\(category.expenseCount) Buechige chöme nach „Diverses“.**
- Zile 150: **Name**
- Zile 151: **z. B. Gschänk**
- Zile 156: **Farb**
- Zile 171: **Farb \(index + 1)**
- Zile 179: **Symbol**
- Zile 204: **Kategorie bearbeite**
- Zile 211: **Sichere**

## Tagesaagabe

`Sackgaeud/Features/Shared/Components.swift`

- Zile 224: **Hüt**
- Zile 227: **Geschter**

## Startset vo de Kategorie

`Sackgaeud/Model/CategorySeed.swift`

- **Ässä uswärts**
- **Snacks**
- **Technik**
- **Hobby**
- **Shopping**
- **Diverses**

## Face ID

`Sackgaeud/Services/AppLock.swift`

- Zile 46: **Sackgäud entsperre**
- Zile 56: **Sperre mit Face ID ischaute**

## Widget

`SackgaeudWidget/SackgaeudWidget.swift`

- Zile 23: **Wie vüu du bis zum 25. no chasch usgäh.**
- Zile 90: **Öffne Sackgäud**
- Zile 92: **Gsperrt**
- Zile 113: **Überzoge**
- Zile 113: **No übrig**
- Zile 123: **\(MoneyFormat.chf(daily)) pro Tag**
- Zile 155: **Überzoge um \(MoneyFormat.chf(-summary.restRappen))**
- Zile 156: **No \(MoneyFormat.chf(summary.restRappen))**

---

**87 Täxt total.**

Nid uf Mundart, mit Absicht: dr Bereich „Entwicklung" i de Istellige (nume i
Debug-Builds sichtbar), Log-Mäudige und d Kommentär im Code. Die si für
Entwickler da, nid für Benutzer.

