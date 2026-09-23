#!/usr/bin/env python3
"""Strukturpruefung fuer Sackgaeud.

Ersetzt keinen Compiler, faengt aber die Fehlerklassen ab, die beim Erzeugen eines
Xcode-Projekts ohne macOS am wahrscheinlichsten sind:

  1. Klammernbilanz in allen Swift-Dateien (unter Beachtung von Kommentaren,
     Zeichenketten, mehrzeiligen Zeichenketten und String-Interpolation)
  2. Deutsche Anfuehrungszeichen in Swift-Zeichenketten: „…“ statt „…" – das
     gerade Zeichen wuerde die Zeichenkette beenden
  3. Wohlgeformtheit aller XML- und JSON-Dateien
  4. project.pbxproj: Klammernbilanz, Aufloesung jeder Objekt-ID, synchronisierte
     Ordner vorhanden, Widget eingebettet
  5. SwiftData-Modelle: jedes gespeicherte Feld hat einen Standardwert oder ist
     optional, keine unique-Attribute, Beziehungen optional (CloudKit-Regeln)
  6. Widget und gemeinsamer Ordner verwenden keine Typen, die nur in der App liegen
     (das Widget-Target sieht nur Shared/ und SackgaeudWidget/)
  7. App Group und iCloud-Container stimmen in Entitlements und Code ueberein
  8. Info.plist-Schluessel, die zur Laufzeit gebraucht werden, sind vorhanden

Aufruf:  python3 tools/verify_structure.py
"""

from __future__ import annotations

import json
import re
import sys
import xml.dom.minidom
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PROBLEMS: list[str] = []
CHECKS: list[str] = []
SWIFT_DIRS = ("Sackgaeud", "Shared", "SackgaeudWidget", "SackgaeudTests")


def problem(message: str) -> None:
    PROBLEMS.append(message)


def ok(message: str) -> None:
    CHECKS.append(message)


def swift_files(*dirs: str) -> list[Path]:
    files: list[Path] = []
    for directory in dirs or SWIFT_DIRS:
        files += sorted((ROOT / directory).rglob("*.swift"))
    return files


def strip_comments(text: str) -> str:
    text = re.sub(r"/\*.*?\*/", "", text, flags=re.DOTALL)
    return re.sub(r"//[^\n]*", "", text)


# ---------------------------------------------------------------- Swift-Klammern

def swift_balance(text: str) -> tuple[int, int, int, str | None]:
    """Zaehlt Klammern ausserhalb von Kommentaren und Zeichenketten."""
    curly = round_ = square = 0
    i, n = 0, len(text)
    line = 1
    # Zustand: 'code' | 'line_comment' | 'block_comment' | 'string' | 'multiline'
    state = "code"
    block_depth = 0
    interpolation: list[int] = []  # offene Klammern in \( ... )

    while i < n:
        ch = text[i]
        nxt = text[i + 1] if i + 1 < n else ""
        if ch == "\n":
            line += 1

        if state == "code":
            if ch == "/" and nxt == "/":
                state = "line_comment"
                i += 2
                continue
            if ch == "/" and nxt == "*":
                state = "block_comment"
                block_depth = 1
                i += 2
                continue
            if text.startswith('"""', i):
                state = "multiline"
                i += 3
                continue
            if ch == '"':
                state = "string"
                i += 1
                continue
            if ch == "{":
                curly += 1
            elif ch == "}":
                curly -= 1
                if curly < 0:
                    return curly, round_, square, f"Zeile {line}: schliessende geschweifte Klammer zu viel"
            elif ch == "(":
                round_ += 1
                if interpolation:
                    interpolation[-1] += 1
            elif ch == ")":
                if interpolation and interpolation[-1] == 0:
                    interpolation.pop()
                    state = "string"
                    i += 1
                    continue
                round_ -= 1
                if interpolation:
                    interpolation[-1] -= 1
                if round_ < 0:
                    return curly, round_, square, f"Zeile {line}: schliessende runde Klammer zu viel"
            elif ch == "[":
                square += 1
            elif ch == "]":
                square -= 1
                if square < 0:
                    return curly, round_, square, f"Zeile {line}: schliessende eckige Klammer zu viel"
            i += 1
            continue

        if state == "line_comment":
            if ch == "\n":
                state = "code"
            i += 1
            continue

        if state == "block_comment":
            if ch == "/" and nxt == "*":
                block_depth += 1
                i += 2
                continue
            if ch == "*" and nxt == "/":
                block_depth -= 1
                i += 2
                if block_depth == 0:
                    state = "code"
                continue
            i += 1
            continue

        if state == "string":
            if ch == "\\" and nxt == "(":
                interpolation.append(0)
                state = "code"
                i += 2
                continue
            if ch == "\\":
                i += 2
                continue
            if ch == '"':
                state = "code"
            if ch == "\n":  # einzeilige Zeichenkette darf keinen Zeilenumbruch enthalten
                return curly, round_, square, f"Zeile {line}: Zeichenkette nicht geschlossen"
            i += 1
            continue

        if state == "multiline":
            if ch == "\\" and nxt == "(":
                interpolation.append(0)
                state = "code"
                i += 2
                continue
            if ch == "\\":
                i += 2
                continue
            if text.startswith('"""', i):
                state = "code"
                i += 3
                continue
            i += 1
            continue

    if state != "code":
        return curly, round_, square, f"Datei endet im Zustand '{state}'"
    return curly, round_, square, None


def check_swift_files() -> None:
    files = swift_files()
    if not files:
        problem("Keine Swift-Dateien gefunden.")
        return
    for path in files:
        text = path.read_text(encoding="utf-8")
        curly, round_, square, error = swift_balance(text)
        rel = path.relative_to(ROOT)
        if error:
            problem(f"{rel}: {error}")
            continue
        if curly or round_ or square:
            problem(
                f"{rel}: Klammern unausgeglichen "
                f"(geschweift {curly:+d}, rund {round_:+d}, eckig {square:+d})"
            )
    ok(f"Klammernbilanz in {len(files)} Swift-Dateien geprueft")


def check_german_quotes() -> None:
    # „ gefolgt von einem geraden " ohne “ oder Backslash dazwischen. Der Backslash
    # ist ausgenommen, damit Interpolationen wie „\(name ?? "")“ nicht stoeren.
    pattern = re.compile('\u201e([^\u201c"\\\\]*)"')
    for path in swift_files():
        for number, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
            if line.strip().startswith("//"):
                continue
            for match in pattern.finditer(line):
                problem(
                    f"{path.relative_to(ROOT)}:{number}: \u201e{match.group(1)}\" – schliessendes "
                    "Anfuehrungszeichen muss \u201c sein, sonst endet die Zeichenkette hier."
                )
    ok("Deutsche Anfuehrungszeichen in Zeichenketten geprueft")


# ------------------------------------------------------------------ XML und JSON

def check_xml_and_json() -> None:
    xml_suffixes = {".xml", ".entitlements", ".xcscheme", ".xcworkspacedata", ".plist", ".xccurrentversion"}
    xml_files = [p for p in ROOT.rglob("*") if p.is_file() and p.suffix in xml_suffixes and ".git" not in p.parts]
    for path in xml_files:
        try:
            xml.dom.minidom.parse(str(path))
        except Exception as error:  # noqa: BLE001
            problem(f"{path.relative_to(ROOT)}: XML nicht wohlgeformt – {error}")
    ok(f"{len(xml_files)} XML-Dateien wohlgeformt")

    json_files = [p for p in ROOT.rglob("*.json") if ".git" not in p.parts]
    json_files += [p for p in ROOT.rglob("*.xcstrings") if ".git" not in p.parts]
    for path in json_files:
        try:
            json.loads(path.read_text(encoding="utf-8"))
        except Exception as error:  # noqa: BLE001
            problem(f"{path.relative_to(ROOT)}: JSON ungueltig – {error}")
    ok(f"{len(json_files)} JSON-Dateien gueltig")



# --------------------------------------------------------------------- pbxproj

def check_pbxproj() -> None:
    path = ROOT / "Sackgaeud.xcodeproj" / "project.pbxproj"
    if not path.exists():
        problem("project.pbxproj fehlt.")
        return
    text = path.read_text(encoding="utf-8")

    if text.count("{") != text.count("}"):
        problem(f"project.pbxproj: geschweifte Klammern unausgeglichen ({text.count('{')} auf, {text.count('}')} zu)")
    if text.count("(") != text.count(")"):
        problem(f"project.pbxproj: runde Klammern unausgeglichen ({text.count('(')} auf, {text.count(')')} zu)")

    defined_list = re.findall(r"^\t\t([0-9A-F]{24})\s*(?:/\*.*?\*/\s*)?=", text, re.MULTILINE)
    defined = set(defined_list)
    if len(defined_list) != len(defined):
        problem("project.pbxproj: eine Objekt-ID ist doppelt definiert.")
    referenced = set(re.findall(r"\b([0-9A-F]{24})\b", text))
    missing = sorted(referenced - defined)
    if missing:
        problem(f"project.pbxproj: referenzierte, aber nicht definierte Objekte: {', '.join(missing)}")

    root_match = re.search(r"rootObject = ([0-9A-F]{24})", text)
    if not root_match or root_match.group(1) not in defined:
        problem("project.pbxproj: rootObject fehlt oder zeigt ins Leere.")

    for section in ("PBXNativeTarget", "PBXProject", "XCConfigurationList", "XCBuildConfiguration",
                    "PBXCopyFilesBuildPhase", "PBXTargetDependency"):
        if f"/* Begin {section} section */" not in text or f"/* End {section} section */" not in text:
            problem(f"project.pbxproj: Abschnitt {section} unvollstaendig.")

    for group_path in re.findall(r"isa = PBXFileSystemSynchronizedRootGroup;.*?path = (\w+);", text):
        if not (ROOT / group_path).is_dir():
            problem(f"project.pbxproj: synchronisierter Ordner '{group_path}' existiert nicht.")

    if "dstSubfolderSpec = 13;" not in text or "SackgaeudWidget.appex in Embed Foundation Extensions" not in text:
        problem("project.pbxproj: Das Widget wird nicht in die App eingebettet.")

    for setting in ("CODE_SIGN_ENTITLEMENTS", "INFOPLIST_FILE"):
        for value in set(re.findall(rf"\b{setting} = ([^;]+);", text)):
            rel = value.strip().strip('"')
            if not (ROOT / rel).exists():
                problem(f"Build-Einstellung {setting} zeigt auf '{rel}', die Datei fehlt.")
    if not (ROOT / "Config/Signing.xcconfig").exists():
        problem("Config/Signing.xcconfig fehlt.")

    # Info.plist-Dateien duerfen nicht in synchronisierten Ordnern liegen: Xcode
    # wuerde sie sonst zusaetzlich als Ressource kopieren und den Build abbrechen.
    for directory in SWIFT_DIRS:
        for plist in (ROOT / directory).rglob("Info.plist"):
            problem(f"{plist.relative_to(ROOT)}: Info.plist gehoert nach Config/, nicht in einen synchronisierten Ordner.")

    scheme = ROOT / "Sackgaeud.xcodeproj/xcshareddata/xcschemes/Sackgaeud.xcscheme"
    if scheme.exists():
        for blueprint in re.findall(r'BlueprintIdentifier = "([0-9A-F]{24})"', scheme.read_text(encoding="utf-8")):
            if blueprint not in defined:
                problem(f"Schema verweist auf unbekanntes Target {blueprint}.")
    else:
        problem("Geteiltes Schema fehlt.")

    ok(f"project.pbxproj: {len(defined)} Objekte definiert, alle Referenzen aufloesbar")


# ------------------------------------------------------------------- SwiftData

def check_models() -> None:
    models = 0
    for path in swift_files("Sackgaeud"):
        text = strip_comments(path.read_text(encoding="utf-8"))
        for match in re.finditer(r"@Model\s+final class (\w+)\s*\{", text):
            models += 1
            name = match.group(1)
            body_start = match.end()
            depth, i = 1, body_start
            while depth and i < len(text):
                depth += {"{": 1, "}": -1}.get(text[i], 0)
                i += 1
            body = text[body_start:i - 1]
            # nur Deklarationen auf oberster Ebene der Klasse
            top, depth = [], 0
            for line in body.splitlines():
                if depth == 0:
                    top.append(line)
                depth += line.count("{") - line.count("}")
            for line in top:
                stripped = line.strip()
                decl = re.match(r"(?:@\w+(?:\([^)]*\))?\s*)*var (\w+)\s*:\s*([^=]+?)(?:\s*=\s*(.+))?$", stripped)
                if not decl or "{" in stripped:
                    continue  # berechnete Eigenschaft
                prop, type_, default = decl.group(1), decl.group(2).strip(), decl.group(3)
                if default is None and not type_.endswith("?"):
                    problem(f"{path.relative_to(ROOT)}: {name}.{prop} hat weder Standardwert noch ist es optional – CloudKit lehnt das ab.")
                if re.match(r"\[?\w+\]\?|\w+\?", type_) is None and type_ in {"Expense", "SpendingCategory", "BudgetAmount", "[Expense]", "[SpendingCategory]"}:
                    problem(f"{path.relative_to(ROOT)}: Beziehung {name}.{prop} muss optional sein.")
            if ".unique" in body:
                problem(f"{path.relative_to(ROOT)}: {name} nutzt @Attribute(.unique) – mit CloudKit nicht erlaubt.")
    ok(f"SwiftData: {models} Modelle gegen die CloudKit-Regeln geprueft")


# ------------------------------------------------------------ Target-Grenzen

def declared_types(directory: str) -> set[str]:
    names: set[str] = set()
    for path in swift_files(directory):
        text = strip_comments(path.read_text(encoding="utf-8"))
        names |= set(re.findall(r"^\s*(?:@\w+\s+)*(?:private\s+|fileprivate\s+)?(?:final\s+)?(?:struct|class|enum|protocol)\s+(\w+)", text, re.MULTILINE))
    return names


def check_target_boundaries() -> None:
    app_only = declared_types("Sackgaeud") - declared_types("Shared") - declared_types("SackgaeudWidget")
    for directory in ("Shared", "SackgaeudWidget"):
        for path in swift_files(directory):
            text = strip_comments(path.read_text(encoding="utf-8"))
            text = re.sub(r'"(?:[^"\\]|\\.)*"', '""', text)
            for name in sorted(app_only):
                if re.search(rf"\b{name}\b", text):
                    problem(f"{path.relative_to(ROOT)}: verwendet '{name}', das nur im App-Target liegt – das Widget sieht es nicht.")
            if "import SwiftData" in text:
                problem(f"{path.relative_to(ROOT)}: Shared/Widget soll SwiftData nicht importieren (Widget liest nur den Schnappschuss).")
    ok(f"Widget und Shared/ verwenden keine der {len(app_only)} App-eigenen Typen")


# --------------------------------------------------------------- Kennungen

def plist_strings(path: Path, key: str) -> list[str]:
    document = xml.dom.minidom.parse(str(path))
    values: list[str] = []
    for node in document.getElementsByTagName("key"):
        if node.firstChild and node.firstChild.data == key:
            sibling = node.nextSibling
            while sibling is not None and sibling.nodeType != sibling.ELEMENT_NODE:
                sibling = sibling.nextSibling
            if sibling is not None:
                values += [s.firstChild.data for s in sibling.getElementsByTagName("string") if s.firstChild]
                if sibling.tagName == "string" and sibling.firstChild:
                    values.append(sibling.firstChild.data)
    return values


def check_identifiers() -> None:
    app_ent = ROOT / "Config/Sackgaeud.entitlements"
    widget_ent = ROOT / "Config/SackgaeudWidget.entitlements"
    shared = (ROOT / "Shared/Domain/WidgetSnapshot.swift").read_text(encoding="utf-8")
    factory = (ROOT / "Sackgaeud/Persistence/ModelContainerFactory.swift").read_text(encoding="utf-8")

    group = re.search(r'appGroup = "([^"]+)"', shared)
    container = re.search(r'cloudKitContainer = "([^"]+)"', factory)
    if not group or not container:
        problem("App-Group- oder iCloud-Kennung im Code nicht gefunden.")
        return
    for ent in (app_ent, widget_ent):
        if group.group(1) not in plist_strings(ent, "com.apple.security.application-groups"):
            problem(f"{ent.relative_to(ROOT)}: App Group '{group.group(1)}' fehlt.")
    if container.group(1) not in plist_strings(app_ent, "com.apple.developer.icloud-container-identifiers"):
        problem(f"Config/Sackgaeud.entitlements: iCloud-Container '{container.group(1)}' fehlt.")
    for key in ("aps-environment", "com.apple.developer.icloud-services"):
        if key not in app_ent.read_text(encoding="utf-8"):
            problem(f"Config/Sackgaeud.entitlements: '{key}' fehlt.")
    ok("App Group und iCloud-Container stimmen in Entitlements und Code ueberein")


# ------------------------------------------------------------------- Info.plist

KEYS_REQUIRING_REAL_PLIST = ["UIBackgroundModes", "ITSAppUsesNonExemptEncryption", "NSExtension"]


def check_info_plists() -> None:
    pbx = (ROOT / "Sackgaeud.xcodeproj" / "project.pbxproj").read_text(encoding="utf-8")
    app = (ROOT / "Config/Info.plist").read_text(encoding="utf-8")
    widget = (ROOT / "Config/Widget-Info.plist").read_text(encoding="utf-8")
    if "remote-notification" not in app:
        problem("Config/Info.plist: UIBackgroundModes/remote-notification fehlt – iCloud-Aenderungen kaemen nicht an.")
    if "UIUserInterfaceStyle" not in app:
        problem("Config/Info.plist: UIUserInterfaceStyle fehlt.")
    if "com.apple.widgetkit-extension" not in widget:
        problem("Config/Widget-Info.plist: NSExtensionPointIdentifier fehlt – ohne ist es kein Widget.")
    if "INFOPLIST_KEY_NSFaceIDUsageDescription" not in pbx:
        problem("project.pbxproj: Face-ID-Begruendung fehlt – die App stuerzt beim ersten Face-ID-Aufruf ab.")
    for key in KEYS_REQUIRING_REAL_PLIST:
        if f"INFOPLIST_KEY_{key}" in pbx:
            problem(f"project.pbxproj: INFOPLIST_KEY_{key} wird von Xcode nicht ausgewertet.")
    ok("Info.plist-Dateien enthalten die Laufzeit-Schluessel")


# ------------------------------------------------------------------------ Start

def main() -> int:
    check_swift_files()
    check_german_quotes()
    check_xml_and_json()
    check_pbxproj()
    check_models()
    check_target_boundaries()
    check_identifiers()
    check_info_plists()

    print("Sackgaeud – Strukturpruefung\n")
    for line in CHECKS:
        print(f"  [ok] {line}")
    if PROBLEMS:
        print("\nGefundene Probleme:\n")
        for line in PROBLEMS:
            print(f"  [!!] {line}")
        print(f"\n{len(PROBLEMS)} Problem(e). Das ersetzt keinen Compiler – der Build-Nachweis liegt in Xcode.")
        return 1
    print("\nKeine strukturellen Probleme gefunden.")
    print("Wichtig: Das ist kein Compiler. Den Build-Nachweis liefert erst Xcode (Cmd+B).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
