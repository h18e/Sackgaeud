import Foundation

/// Umgang mit Franken-Beträgen (SPEC 2.4).
///
/// Gespeichert und gerechnet wird in **ganzen Rappen** (`Int`). Gerundet wird erst
/// für die Anzeige, und zwar kaufmännisch auf 5 Rappen.
enum MoneyFormat {

    /// Höchster erlaubter Betrag einer Eingabe: CHF 99'999.95.
    static let maximumRappen = 9_999_995

    // MARK: - Eingabe

    /// Liest eine Eingabe wie „12", „12.5", „12,50", „1'234.55" oder „CHF 8.–".
    ///
    /// `nil`, wenn die Eingabe keine gültige Zahl ist, mehr als zwei Nachkommastellen
    /// hat, 0 ist oder über dem Höchstbetrag liegt.
    static func parse(_ input: String) -> Int? {
        var text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.uppercased().hasPrefix("CHF") {
            text = String(text.dropFirst(3))
        }
        text = text
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "\u{00A0}", with: "")
            .replacingOccurrences(of: "'", with: "")
            .replacingOccurrences(of: "’", with: "")
            .replacingOccurrences(of: ",", with: ".")
        if text.hasSuffix(".–") || text.hasSuffix(".-") {
            text = String(text.dropLast(2))
        }
        guard !text.isEmpty else { return nil }

        let parts = text.split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count <= 2 else { return nil }

        let francsText = parts[0].isEmpty ? "0" : String(parts[0])
        guard francsText.allSatisfy(\.isASCIIDigitCharacter),
              francsText.count <= 6,
              let francs = Int(francsText) else { return nil }

        var cents = 0
        if parts.count == 2 {
            let centsText = String(parts[1])
            guard centsText.count <= 2, centsText.allSatisfy(\.isASCIIDigitCharacter) else { return nil }
            if !centsText.isEmpty {
                cents = Int(centsText.padding(toLength: 2, withPad: "0", startingAt: 0)) ?? 0
            }
        }

        let total = francs * 100 + cents
        guard total > 0, total <= maximumRappen else { return nil }
        return total
    }

    /// Umkehrung von `parse` für das Bearbeiten: „12.50" oder „12", ohne Tausendertrennung.
    static func inputText(_ rappen: Int) -> String {
        let francs = rappen / 100
        let cents = rappen % 100
        return cents == 0 ? "\(francs)" : "\(francs).\(twoDigits(cents))"
    }

    // MARK: - Rundung

    /// Kaufmännisch auf 5 Rappen: …1 und …2 abwärts, …3 und …4 aufwärts.
    /// Negative Beträge spiegelbildlich.
    static func roundedToFiveRappen(_ rappen: Int) -> Int {
        if rappen < 0 { return -roundedToFiveRappen(-rappen) }
        return (rappen + 2) / 5 * 5
    }

    // MARK: - Anzeige

    /// „CHF 1'234.55", „CHF 40.–", „CHF −35.–". Immer auf 5 Rappen gerundet.
    static func chf(_ rappen: Int) -> String {
        "CHF \(amount(rappen))"
    }

    /// Wie `chf`, aber ohne Währung: „1'234.55", „40.–", „−35.–".
    static func amount(_ rappen: Int) -> String {
        let rounded = roundedToFiveRappen(rappen)
        let sign = rounded < 0 ? "\u{2212}" : ""
        let absolute = abs(rounded)
        let francs = absolute / 100
        let cents = absolute % 100
        let centsText = cents == 0 ? "–" : twoDigits(cents)
        return "\(sign)\(grouped(francs)).\(centsText)"
    }

    /// Text für VoiceOver: „35 Franke 50", „40 Franke", „minus 35 Franke".
    static func spoken(_ rappen: Int) -> String {
        let rounded = roundedToFiveRappen(rappen)
        let prefix = rounded < 0 ? "minus " : ""
        let absolute = abs(rounded)
        let francs = absolute / 100
        let cents = absolute % 100
        let francsText = "\(francs) Franke"
        return cents == 0 ? prefix + francsText : "\(prefix)\(francsText) \(cents)"
    }

    // MARK: - Hilfen

    /// Tausendertrennung mit Apostroph, wie in der Schweiz üblich: 1'234'567.
    static func grouped(_ value: Int) -> String {
        let digits = String(value)
        var result = ""
        for (index, character) in digits.enumerated() {
            if index > 0, (digits.count - index) % 3 == 0 {
                result.append("'")
            }
            result.append(character)
        }
        return result
    }

    private static func twoDigits(_ value: Int) -> String {
        value < 10 ? "0\(value)" : "\(value)"
    }
}

private extension Character {
    var isASCIIDigitCharacter: Bool {
        ("0"..."9").contains(self)
    }
}
