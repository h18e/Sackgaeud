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
- Zile 128: **No nüt erfasst**
- Zile 129: **Tipp uf „Usgab erfasse“, sobald du öppis zahlt hesch.**
- Zile 160: **vo \(MoneyFormat.chf(summary.amountRappen))**
- Zile 176: **Überzoge um \(MoneyFormat.spoken(-summary.restRappen)), vo \(MoneyFormat.spoken(summary.amountRappen))**
- Zile 178: **No \(MoneyFormat.spoken(summary.restRappen)) übrig, vo \(MoneyFormat.spoken(summary.amountRappen))**
- Zile 195: **Defizit us früechere Periode**
- Zile 207: **Zum Uusglyche: höchschtens \(MoneyFormat.chf(daily)) pro Tag bis zum 24.**
- Zile 209: **Die Periode reicht nid für e ganze Uusglych – o ohni wyteri Usgabe blybe \(MoneyFormat.chf(-status.spendableAfterCompensation)) offe.**
- Zile 212: **Am 25.12. fangt ds Defizit wieder bi null a.**
- Zile 233: **Überzoge um \(MoneyFormat.chf(-summary.restRappen))**
- Zile 238: **No \(MoneyFormat.chf(daily)) pro Tag für \(DailyLine.days(summary.remainingDays))**
- Zile 247: **1 Tag**
- Zile 247: **\(count) Täg**

## Usgab erfasse & bearbeite

`Sackgaeud/Features/ExpenseEditor/ExpenseEditorView.swift`

- Zile 66: **Buechig bearbeite**
- Zile 66: **Usgab erfasse**
- Zile 70: **Abbräche**
- Zile 73: **Sichere**
- Zile 101: **Betrag i Franke**
- Zile 127: **Notiz (fryywillig)**
- Zile 142: **Chunnt i \(period.title())**
- Zile 156: **Buechig lösche**

## Buechige-Liste

`Sackgaeud/Features/ExpenseEditor/ExpenseSections.swift`

- Zile 45: **Lösche**

## Verlouf

`Sackgaeud/Features/History/HistoryView.swift`

- Zile 68: **Lösche**
- Zile 78: **Lösche chasch nume Periode us früechere Jahr – so blybt es offes Defizit bis zum 24.12. geng sichtbar.**
- Zile 83: **Verlouf**
- Zile 89: **Früecheri Jahr lösche**
- Zile 107: **Abbräche**
- Zile 111: **Das cha nid rückgängig gmacht wärde.**
- Zile 117: **1 Buechig**
- Zile 117: **\(count) Buechige**
- Zile 145: **Defizit \(amount) · am 25.12. zrüggsetzt**
- Zile 145: **Defizit \(amount)**
- Zile 153: **\(row.period.rangeText()) · louft no**
- Zile 185: **überzoge**
- Zile 185: **no übrig**
- Zile 185: **übrig**
- Zile 195: **\u{2212} \(MoneyFormat.chf(-rest))**
- Zile 195: **+ \(MoneyFormat.chf(rest))**
- Zile 200: **Überzoge um \(MoneyFormat.spoken(-rest))**
- Zile 200: **\(MoneyFormat.spoken(rest)) übrig**

## Periode im Detail

`Sackgaeud/Features/History/PeriodDetailView.swift`

- Zile 69: **Usgabe**
- Zile 73: **Ergäbnis**
- Zile 79: **Defizit vorhär**
- Zile 85: **Defizit nachhär**
- Zile 99: **Nach Kategorie**
- Zile 108: **\(Int((Double(entry.rappen) / Double(total) * 100).rounded())) %**
- Zile 118: **Kei Buechige i dere Periode**

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

- Zile 235: **Hüt**
- Zile 238: **Geschter**

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

**103 Täxt total.**

Nid uf Mundart, mit Absicht: dr Bereich „Entwicklung" i de Istellige (nume i
Debug-Builds sichtbar), Log-Mäudige und d Kommentär im Code. Die si für
Entwickler da, nid für Benutzer.

