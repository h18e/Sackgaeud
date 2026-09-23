import SwiftUI
import WidgetKit

/// Widget mit dem Restbetrag (SPEC 4.7) – nur Anzeige, Antippen öffnet die App.
///
/// Liest den Schnappschuss, den die App in die App Group schreibt, und rechnet
/// daraus für jeden Zeitpunkt Rest und Tagesbudget selbst aus. Deshalb stimmt die
/// Anzeige auch um Mitternacht und am 25., ohne dass die App laufen muss.
@main
struct SackgaeudWidgetBundle: WidgetBundle {
    var body: some Widget {
        RestWidget()
    }
}

struct RestWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: SharedStore.widgetKind, provider: RestProvider()) { entry in
            RestWidgetView(entry: entry)
                .containerBackground(Theme.background, for: .widget)
        }
        .configurationDisplayName("Sackgäud")
        .description("Wie vüu du bis zum 25. no chasch usgäh.")
        .supportedFamilies([.systemSmall, .accessoryRectangular, .accessoryInline])
    }
}

// MARK: - Daten

struct RestEntry: TimelineEntry {
    let date: Date
    let content: Content

    enum Content {
        /// App noch nie geöffnet oder App Group fehlt.
        case empty
        /// Face-ID-Sperre aktiv: kein Betrag (SPEC 9, Punkt 4).
        case locked
        case summary(period: BudgetPeriod, summary: BudgetSummary)
    }

    static func make(at date: Date) -> RestEntry {
        if SharedStore.isAppLockEnabled {
            return RestEntry(date: date, content: .locked)
        }
        guard let snapshot = SharedStore.loadSnapshot() else {
            return RestEntry(date: date, content: .empty)
        }
        let result = snapshot.summary(at: date)
        return RestEntry(date: date, content: .summary(period: result.period, summary: result.summary))
    }
}

struct RestProvider: TimelineProvider {

    func placeholder(in context: Context) -> RestEntry {
        let period = BudgetPeriod(containing: .now)
        let summary = BudgetSummary(amountRappen: 150_000, spentRappen: 62_000, remainingDays: 18)
        return RestEntry(date: .now, content: .summary(period: period, summary: summary))
    }

    func getSnapshot(in context: Context, completion: @escaping (RestEntry) -> Void) {
        completion(context.isPreview ? placeholder(in: context) : RestEntry.make(at: .now))
    }

    /// Ein Eintrag jetzt und je einer um Mitternacht der nächsten sieben Tage – dann
    /// ändert sich das Tagesbudget, und am 25. beginnt die neue Periode.
    func getTimeline(in context: Context, completion: @escaping (Timeline<RestEntry>) -> Void) {
        let calendar = Calendar.current
        var entries = [RestEntry.make(at: .now)]
        var midnight = calendar.startOfDay(for: .now)
        for _ in 0..<7 {
            guard let next = calendar.date(byAdding: .day, value: 1, to: midnight) else { break }
            midnight = next
            entries.append(RestEntry.make(at: midnight))
        }
        completion(Timeline(entries: entries, policy: .atEnd))
    }
}

// MARK: - Darstellung

struct RestWidgetView: View {
    let entry: RestEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch entry.content {
        case .empty:
            message(symbol: "banknote", text: "Öffne Sackgäud")
        case .locked:
            message(symbol: "lock.fill", text: "Gsperrt")
        case let .summary(period, summary):
            switch family {
            case .accessoryInline:
                Text(inlineText(summary))
            case .accessoryRectangular:
                rectangular(summary)
            default:
                small(period: period, summary: summary)
            }
        }
    }

    // MARK: Home-Bildschirm

    private func small(period: BudgetPeriod, summary: BudgetSummary) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(period.title())
                .font(.caption2)
                .foregroundStyle(Theme.textSecondary)
            Spacer(minLength: 0)
            Text(summary.isOverdrawn ? "Überzoge" : "No übrig")
                .font(.caption)
                .foregroundStyle(summary.isOverdrawn ? Theme.negative : Theme.textSecondary)
            Text(MoneyFormat.chf(summary.restRappen))
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(Theme.restColor(isOverdrawn: summary.isOverdrawn))
                .minimumScaleFactor(0.5)
                .lineLimit(1)
            if let daily = summary.dailyRappen {
                Text("\(MoneyFormat.chf(daily)) pro Tag")
                    .font(.caption)
                    .monospacedDigit()
                    .foregroundStyle(Theme.accent)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    }

    // MARK: Sperrbildschirm

    private func rectangular(_ summary: BudgetSummary) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(summary.isOverdrawn ? "Überzoge" : "Sackgäud")
                .font(.caption2)
                .widgetAccentable()
            Text(MoneyFormat.chf(summary.restRappen))
                .font(.headline)
                .monospacedDigit()
            if let daily = summary.dailyRappen {
                Text("\(MoneyFormat.chf(daily)) pro Tag")
                    .font(.caption)
                    .monospacedDigit()
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func inlineText(_ summary: BudgetSummary) -> String {
        summary.isOverdrawn
            ? "Überzoge um \(MoneyFormat.chf(-summary.restRappen))"
            : "No \(MoneyFormat.chf(summary.restRappen))"
    }

    private func message(symbol: String, text: String) -> some View {
        Group {
            if family == .accessoryInline {
                Label(text, systemImage: symbol)
            } else {
                VStack(spacing: 6) {
                    Image(systemName: symbol)
                        .font(.title3)
                    Text(text)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                }
                .foregroundStyle(family == .systemSmall ? Theme.textSecondary : .primary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}
