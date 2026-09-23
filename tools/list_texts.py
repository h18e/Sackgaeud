#!/usr/bin/env python3
"""Listet alle sichtbaren Texte der App und schreibt sie nach TEXTE.md.

Zweck: eine vollstaendige, aus dem Quellcode erzeugte Uebersicht der Mundart-Texte,
damit einzelne Formulierungen gezielt angepasst werden koennen.

Nicht enthalten: der nur in Debug-Builds sichtbare Bereich "Entwicklung",
Log-Meldungen, SF-Symbol-Namen und technische Bezeichner.

Aufruf:  python3 tools/list_texts.py
"""

from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent

SCREENS = [
    ('Sackgaeud/App/RootView.swift', 'Sperre & Rückgängig'),
    ('Sackgaeud/Features/Onboarding/OnboardingView.swift', 'Erschte Start'),
    ('Sackgaeud/Features/Overview/OverviewView.swift', 'Hauptbildschirm'),
    ('Sackgaeud/Features/ExpenseEditor/ExpenseEditorView.swift', 'Usgab erfasse & bearbeite'),
    ('Sackgaeud/Features/ExpenseEditor/ExpenseSections.swift', 'Buechige-Liste'),
    ('Sackgaeud/Features/History/HistoryView.swift', 'Verlouf'),
    ('Sackgaeud/Features/History/PeriodDetailView.swift', 'Periode im Detail'),
    ('Sackgaeud/Features/Settings/SettingsView.swift', 'Istellige'),
    ('Sackgaeud/Features/Settings/CategoryListView.swift', 'Istellige → Kategorie'),
    ('Sackgaeud/Features/Shared/Components.swift', 'Tagesaagabe'),
    ('Sackgaeud/Model/CategorySeed.swift', 'Startset vo de Kategorie'),
    ('Sackgaeud/Services/AppLock.swift', 'Face ID'),
    ('SackgaeudWidget/SackgaeudWidget.swift', 'Widget'),
]

# Technische Zeichenketten und Woerter, die in jeder Sprache gleich heissen.
TECH = re.compile(
    r'^([a-z][a-zA-Z0-9]*(\.[a-zA-Z0-9]+)+|[a-z0-9_.\-]+|[A-Za-z]+[A-Z][a-z]+\w*|[\s·–—%@+?]+'
    r'|de_CH|OK|CHF|Version|Über|Kategorie|Datum|Betrag|Sackgäud|Diverses|Mobilität'
    r'|CFBundle\w+|\d+|[0-9A-F\-]{36}|[EMdy ]+)$'
)
SKIP_LINE = ('logger.', 'Logger(', 'fatalError(', 'forResource', '#Preview', 'uuidString:',
             'identifier:', 'Template(', 'DateFormat', 'dateFormat', 'forKey', 'pendingDeletion?.name')


def collect(rel: str) -> list[tuple[int, str]]:
    path = ROOT / rel
    seen: set[str] = set()
    hits: list[tuple[int, str]] = []
    in_debug = False

    for number, line in enumerate(path.read_text(encoding='utf-8').splitlines(), 1):
        if '#if DEBUG' in line:
            in_debug = True
        if '#endif' in line:
            in_debug = False
        if in_debug:
            continue
        stripped = line.strip()
        if stripped.startswith(('//', '///', '*')) or any(k in line for k in SKIP_LINE):
            continue
        for match in re.finditer(r'"([^"\\]*(?:\\.[^"\\]*)*)"', line):
            text = match.group(1)
            if len(text) < 2 or TECH.match(text) or re.fullmatch(r'\\\(.*\)', text):
                continue
            if text in seen:
                continue
            seen.add(text)
            hits.append((number, text))
    return hits


def seed_names() -> list[str]:
    text = (ROOT / 'Sackgaeud/Model/CategorySeed.swift').read_text(encoding='utf-8')
    return re.findall(r'name: "([^"]+)"', text)


def main() -> None:
    out = [
        "# Sackgäud – aui Täxt i dr App",
        "",
        "Automatisch us em Quellcode erzeugt mit `tools/list_texts.py`.",
        "Platzhalter wie `\\(period.title())` wärde zur Laufzyt dür dr richtig Wärt ersetzt.",
        "",
        "Wenn dir öppis nid passt: säg mer d Zile, i ändere's.",
        "",
        "---",
        "",
    ]
    total = 0
    for rel, screen in SCREENS:
        hits = collect(rel)
        if rel.endswith('CategorySeed.swift'):
            hits = [(0, name) for name in seed_names()]
        if not hits:
            continue
        out += [f"## {screen}", "", f"`{rel}`", ""]
        for number, text in hits:
            out.append(f"- Zile {number}: **{text}**" if number else f"- **{text}**")
            total += 1
        out.append("")

    out += [
        "---",
        "",
        f"**{total} Täxt total.**",
        "",
        "Nid uf Mundart, mit Absicht: dr Bereich „Entwicklung\" i de Istellige (nume i",
        "Debug-Builds sichtbar), Log-Mäudige und d Kommentär im Code. Die si für",
        "Entwickler da, nid für Benutzer.",
        "",
    ]
    (ROOT / 'TEXTE.md').write_text("\n".join(out) + "\n", encoding='utf-8')
    print(f"TEXTE.md geschrieben: {total} Texte")


if __name__ == '__main__':
    main()
