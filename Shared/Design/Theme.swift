import SwiftUI

/// Farb- und Stilwerte der App – gilt für App und Widget.
///
/// Flächen, Text und Kategorienpalette sind aus Frostify (und damit aus
/// Räpplispauter) übernommen: **Dark Mode als einziges Erscheinungsbild**, tiefer
/// fast schwarzer Hintergrund, leicht aufgehellte Karten.
///
/// Eigene Akzentfarbe: ein warmes Grün, damit man Sackgäud und Frostify
/// auseinanderhält. Weil Grün hier auch „übrig" bedeutet, steht ein Überzug immer
/// rot **und** mit Minus und Text da – nie nur als Farbe.
enum Theme {

    // MARK: - Flächen

    static let background = Color(red: 0.055, green: 0.059, blue: 0.071)
    static let surface = Color(red: 0.094, green: 0.101, blue: 0.121)
    static let surfaceElevated = Color(red: 0.129, green: 0.137, blue: 0.161)
    static let separator = Color.white.opacity(0.08)

    // MARK: - Text

    static let textPrimary = Color.white
    static let textSecondary = Color.white.opacity(0.62)
    static let textTertiary = Color.white.opacity(0.38)

    // MARK: - Akzente

    /// Markenfarbe, warmes Grün (auch als AccentColor im Asset-Katalog hinterlegt).
    static let accent = Color(red: 0.561, green: 0.816, blue: 0.435)

    /// Überzug.
    static let negative = Color(red: 0.965, green: 0.447, blue: 0.447)

    static let cornerRadius: CGFloat = 16

    // MARK: - Kategorien

    /// Farben für die Kategorien, dieselbe Palette wie in Frostify und Räpplispauter.
    static let categoryPalette: [Color] = [
        Color(red: 0.443, green: 0.663, blue: 0.976),   // Blau
        Color(red: 0.976, green: 0.643, blue: 0.376),   // Orange
        Color(red: 0.482, green: 0.827, blue: 0.529),   // Grün
        Color(red: 0.596, green: 0.612, blue: 0.949),   // Indigo
        Color(red: 0.929, green: 0.510, blue: 0.522),   // Rot
        Color(red: 0.361, green: 0.792, blue: 0.827),   // Türkis
        Color(red: 0.878, green: 0.588, blue: 0.925),   // Violett
        Color(red: 0.902, green: 0.796, blue: 0.404)    // Gelb
    ]

    static func categoryColor(_ index: Int) -> Color {
        guard !categoryPalette.isEmpty else { return accent }
        let safe = ((index % categoryPalette.count) + categoryPalette.count) % categoryPalette.count
        return categoryPalette[safe]
    }

    /// Farbe eines Restbetrags: weiss, solange etwas übrig ist, sonst rot.
    static func restColor(isOverdrawn: Bool) -> Color {
        isOverdrawn ? negative : textPrimary
    }
}
