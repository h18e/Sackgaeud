import Testing
@testable import Sackgaeud

@Suite("Beträge lesen, runden und anzeigen")
struct MoneyFormatTests {

    @Test("Eingaben", arguments: [
        ("12", 1_200), ("12.5", 1_250), ("12,50", 1_250), ("0.05", 5), (".5", 50),
        ("1'234.55", 123_455), ("CHF 8.–", 800), (" 7 ", 700), ("99999.95", 9_999_995)
    ])
    func parses(input: String, expected: Int) {
        #expect(MoneyFormat.parse(input) == expected)
    }

    @Test("Ungültige Eingaben", arguments: ["", "0", "0.00", "abc", "1.234", "1.2.3", "-5", "100000", "12,5x"])
    func rejects(input: String) {
        #expect(MoneyFormat.parse(input) == nil)
    }

    @Test("Punkt am Ende gilt, damit man beim Tippen nicht blockiert wird")
    func trailingDot() {
        #expect(MoneyFormat.parse("12.") == 1_200)
    }

    @Test("Kaufmännisch auf 5 Rappen", arguments: [
        (0, 0), (1, 0), (2, 0), (3, 5), (4, 5), (5, 5), (7, 5), (8, 10), (1_247, 1_245), (1_248, 1_250),
        (-3, -5), (-2, 0)
    ])
    func rounds(rappen: Int, expected: Int) {
        #expect(MoneyFormat.roundedToFiveRappen(rappen) == expected)
    }

    @Test("Anzeige")
    func display() {
        #expect(MoneyFormat.chf(4_000) == "CHF 40.–")
        #expect(MoneyFormat.chf(123_455) == "CHF 1'234.55")
        #expect(MoneyFormat.chf(123_457) == "CHF 1'234.55")
        #expect(MoneyFormat.chf(-3_500) == "CHF \u{2212}35.–")
        #expect(MoneyFormat.chf(2) == "CHF 0.–")
        #expect(MoneyFormat.chf(123_456_700) == "CHF 1'234'567.–")
    }

    @Test("Bearbeiten zeigt den genauen Betrag")
    func inputText() {
        #expect(MoneyFormat.inputText(1_250) == "12.50")
        #expect(MoneyFormat.inputText(1_200) == "12")
        #expect(MoneyFormat.inputText(1_207) == "12.07")
    }

    @Test("VoiceOver")
    func spoken() {
        #expect(MoneyFormat.spoken(3_550) == "35 Franke 50")
        #expect(MoneyFormat.spoken(4_000) == "40 Franke")
    }
}
