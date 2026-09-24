import SwiftUI

// MARK: - Seitenaufbau

/// Karten-Hintergrund im App-Stil (aus Frostify übernommen).
struct CardBackground: ViewModifier {
    var padding: CGFloat = 16

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                    .fill(Theme.surface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Theme.cornerRadius, style: .continuous)
                    .stroke(Theme.separator, lineWidth: 1)
            )
    }
}

extension View {
    func card(padding: CGFloat = 16) -> some View {
        modifier(CardBackground(padding: padding))
    }

    /// Einheitlicher, dunkler Bildschirmhintergrund.
    func screenBackground() -> some View {
        background(Theme.background.ignoresSafeArea())
    }

    /// Listen und Formulare auf den dunklen Hintergrund stellen.
    ///
    /// iOS malt sonst seinen eigenen, etwas helleren Systemhintergrund darunter –
    /// die Flächen wirken dann uneinheitlich.
    func themedList() -> some View {
        self
            .scrollContentBackground(.hidden)
            .screenBackground()
    }
}

// MARK: - Kategorien

extension SpendingCategory {
    var color: Color { Theme.categoryColor(colorIndex) }
}

/// Anzeige einer Kategorie, auch für Buchungen ohne Kategorie (Sync-Randfall):
/// die zählen als „Diverses" (SPEC 3.1).
struct CategoryDisplay {
    let name: String
    let symbol: String
    let color: Color

    init(_ category: SpendingCategory?) {
        if let category {
            name = category.name
            symbol = category.symbol
            color = category.color
        } else {
            let fallback = CategorySeed.templates.first { $0.isFallback }
            name = fallback?.name ?? "Diverses"
            symbol = fallback?.symbol ?? "ellipsis.circle"
            color = Theme.categoryColor(fallback?.colorIndex ?? 0)
        }
    }
}

/// Rundes Kategoriensymbol.
struct CategoryIcon: View {
    let display: CategoryDisplay
    var size: CGFloat = 34

    var body: some View {
        ZStack {
            Circle()
                .fill(display.color.opacity(0.18))
            Image(systemName: display.symbol)
                .font(.system(size: size * 0.42))
                .foregroundStyle(display.color)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

// MARK: - Zeilen

/// Eine Buchung in einer Liste: Symbol, Kategorie, Betrag.
struct ExpenseRow: View {
    let expense: Expense
    var showsDate = false

    var body: some View {
        let display = CategoryDisplay(expense.category)
        HStack(spacing: 12) {
            CategoryIcon(display: display)
            VStack(alignment: .leading, spacing: 2) {
                Text(display.name)
                    .foregroundStyle(Theme.textPrimary)
                if !expense.note.isEmpty {
                    Text(expense.note)
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                        .lineLimit(2)
                }
                if showsDate {
                    Text(DayFormat.short(expense.date))
                        .font(.caption)
                        .foregroundStyle(Theme.textSecondary)
                }
            }
            Spacer(minLength: 8)
            Text(MoneyFormat.chf(expense.amountRappen))
                .monospacedDigit()
                .foregroundStyle(Theme.textPrimary)
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText(category: display.name))
    }

    private func accessibilityText(category: String) -> String {
        let amount = MoneyFormat.spoken(expense.amountRappen)
        return expense.note.isEmpty ? "\(category), \(amount)" : "\(category), \(expense.note), \(amount)"
    }
}

/// Zeile mit Beschriftung links und Wert rechts.
struct LabeledValueRow<Value: View>: View {
    let label: String
    @ViewBuilder var value: Value

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .foregroundStyle(Theme.textSecondary)
            Spacer(minLength: 12)
            value
        }
    }
}

/// Leerer Zustand mit Symbol und Text.
struct EmptyStateView: View {
    let symbol: String
    let title: String
    var message: String?

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 40, weight: .light))
                .foregroundStyle(Theme.textTertiary)
            Text(title)
                .font(.headline)
                .foregroundStyle(Theme.textPrimary)
            if let message {
                Text(message)
                    .font(.subheadline)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
    }
}

/// Waagrechter Balken für die Auswertung je Kategorie.
///
/// Bewusst ohne Chart-Framework, wie in Frostify und Räpplispauter: So bleibt die
/// Darstellung im Dark Mode exakt kontrollierbar.
struct BarRow: View {
    let title: String
    var symbolName: String?
    var color: Color = Theme.accent
    let fraction: Double
    let primaryText: String
    var secondaryText: String?

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 8) {
                if let symbolName {
                    Image(systemName: symbolName)
                        .font(.footnote)
                        .foregroundStyle(color)
                        .frame(width: 18)
                }
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(Theme.textPrimary)
                    .lineLimit(1)
                Spacer(minLength: 8)
                VStack(alignment: .trailing, spacing: 0) {
                    Text(primaryText)
                        .font(.subheadline.weight(.semibold))
                        .monospacedDigit()
                        .foregroundStyle(Theme.textPrimary)
                    if let secondaryText {
                        Text(secondaryText)
                            .font(.caption2)
                            .monospacedDigit()
                            .foregroundStyle(Theme.textSecondary)
                    }
                }
            }

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.07))
                    Capsule()
                        .fill(color)
                        .frame(width: max(4, geometry.size.width * min(max(fraction, 0), 1)))
                }
            }
            .frame(height: 6)
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Datum

/// Tagesbeschriftungen in Mundart.
enum DayFormat {

    /// „Hüt", „Geschter" oder „Mi, 23. Sept.".
    static func dayHeader(_ day: Date, today: Date, calendar: Calendar = .current) -> String {
        if calendar.isDate(day, inSameDayAs: today) { return "Hüt" }
        if let yesterday = calendar.date(byAdding: .day, value: -1, to: today),
           calendar.isDate(day, inSameDayAs: yesterday) {
            return "Geschter"
        }
        return formatter("EEEEEEd MMM", calendar: calendar).string(from: day)
    }

    /// „23.09.2026".
    static func short(_ day: Date, calendar: Calendar = .current) -> String {
        formatter("ddMMyyyy", calendar: calendar).string(from: day)
    }

    private static func formatter(_ template: String, calendar: Calendar) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.locale = Locale(identifier: "de_CH")
        formatter.setLocalizedDateFormatFromTemplate(template)
        return formatter
    }
}
