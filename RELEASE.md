# Sackgäud – Checkliste vor einer Veröffentlichung

Alles hier kann nur ein Mensch erledigen: es braucht Zugang zu App Store Connect,
zum CloudKit-Dashboard oder eine gestalterische Entscheidung. Status bitte laufend
nachführen.

Geplant ist zuerst **TestFlight, nur für dich**. Die mit ★ markierten Punkte braucht
es schon dafür; der Rest erst für den öffentlichen App Store.

| Status | Punkt | Was genau |
|---|---|---|
| ☐ | ★ **CloudKit-Schema nach Production** | https://icloud.developer.apple.com/dashboard → Container `iCloud.ch.hebera.sackgaeud` → **Deploy Schema to Production**. Vorher einmal in der Entwicklungsversion eine Ausgabe, eine Kategorie und einen Betrag gesichert haben, damit alle drei Record-Typen existieren. Ohne diesen Schritt gleicht die TestFlight-Version nichts ab. |
| ☐ | ★ **aps-environment auf production** | In `Config/Sackgaeud.entitlements` steht `development`. Für TestFlight und Store muss dort `production` stehen. |
| ☐ | ★ **Versionsnummer** | `MARKETING_VERSION` und `CURRENT_PROJECT_VERSION` in `project.pbxproj` setzen – bei App **und** Widget gleich, sonst lehnt App Store Connect den Build ab. Jede Einreichung braucht eine neue Build-Nummer. |
| ☐ | ★ **App-Icon** | 1024 × 1024 px PNG, **kein Alphakanal**, randlos (keine eigenen runden Ecken), Farbraum sRGB. In Xcode: `Sackgaeud/Resources/Assets.xcassets` → `AppIcon` → Bild hineinziehen. Ein Alphakanal ist der häufigste Ablehnungsgrund. |
| ☐ | ★ **Debug-Abschnitt prüfen** | Der Bereich „Entwicklung" in den Einstellungen (Beispiel-Buchungen) ist mit `#if DEBUG` geklammert und erscheint in Release-Builds nicht. Einmal in der TestFlight-Version gegenprüfen. |
| ☐ | **Datenschutzerklärung veröffentlichen** | Entwurf liegt in `PRIVACY.md`. Braucht eine erreichbare URL. |
| ☐ | **Support-URL** | Schlichte Seite mit Kontaktmöglichkeit. Pflichtfeld. |
| ☐ | **App-Datenschutzangaben** | App Store Connect → **App Privacy** → „Keine Daten erfasst". Die Daten liegen ausschliesslich im privaten iCloud-Bereich des Nutzers. |
| ☐ | **Screenshots** | Pro erforderlicher Gerätegrösse, aus dem Simulator mit ⌘S. Tipp: vorher im Debug-Build „Beispiel-Buchungen erzeugen". |
| ☐ | **Beschreibung, Schlüsselwörter, Kategorie** | Kategorie „Finanzen" (im Projekt bereits als `public.app-category.finance` hinterlegt). |
| ☐ | **Altersfreigabe** | Fragebogen in App Store Connect. |
| ☐ | **Export-Compliance** | In `Config/Info.plist` als „keine nicht-exemptierte Verschlüsselung" hinterlegt; App Store Connect fragt deshalb nicht nach. |

## Bekannte Grenzen dieser Version

- **Widget und zweites Gerät:** Eine Buchung, die auf einem anderen Gerät erfasst
  wurde, erscheint im Widget erst, wenn die App auf diesem Gerät einmal offen war.
  Bei nur einem iPhone spielt das keine Rolle.
- **Gelöschte Startkategorie taucht wieder auf:** Richtest du ein zweites Gerät ein,
  bevor es mit iCloud abgeglichen hat, legt es das Startset an. Eine Startkategorie,
  die du auf dem ersten Gerät gelöscht hattest, kommt dann zurück. Einfach nochmals
  löschen; die Buchungen bleiben dabei erhalten (sie wandern nach „Diverses").
- **Zeitzone:** Die Periode richtet sich nach der Uhr des Geräts. Wer auf Reisen
  am 24./25. die Zeitzone wechselt, kann eine Buchung in der Nachbarperiode sehen.
