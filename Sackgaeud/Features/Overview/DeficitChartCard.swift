import Charts
import SwiftUI

/// Verlauf des Defizits im laufenden Budgetjahr (SPEC 2.5, Nachtrag 24.09.2026).
///
/// Ersetzt die frühere Textkarte. Jeder Punkt ist das offene Defizit zu Beginn einer
/// Periode, von „Januar" bis zur laufenden. Geschwungene Linie, darunter eine Fläche,
/// die von voller Deckkraft an der Linie bis ganz durchsichtig an der x-Achse ausläuft.
///
/// Antippen oder darüberstreichen zeigt den Wert einer Periode.
struct DeficitChartCard: View {
    let points: [DeficitPoint]
    /// Offenes Defizit und Ausgleich in der laufenden Periode.
    let status: DeficitStatus
    let period: BudgetPeriod

    @State private var selectedLabel: String?

    private var current: Int { points.last?.rappen ?? 0 }

    private var selectedPoint: DeficitPoint? {
        guard let selectedLabel else { return nil }
        return points.first { $0.period.shortTitle() == selectedLabel }
    }

    /// Obergrenze der y-Achse mit etwas Luft über dem höchsten Punkt.
    private var yMaximum: Double {
        let highest = Double(points.map(\.rappen).max() ?? 0) / 100
        return max(highest * 1.2, 10)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            chart
                .frame(height: 150)
            footnote
        }
        .card(padding: 14)
    }

    // MARK: - Teile

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Defizit \(String(period.budgetYear))")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.textPrimary)
                Text("offe am Afang vo jeder Periode")
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            }
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 2) {
                Text(MoneyFormat.chf(selectedPoint?.rappen ?? current))
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle((selectedPoint?.rappen ?? current) > 0 ? Theme.negative : Theme.accent)
                Text(selectedPoint.map { $0.period.title() } ?? "jetz")
                    .font(.caption)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
    }

    private var chart: some View {
        Chart {
            ForEach(points) { point in
                let label = point.period.shortTitle()
                let francs = Double(point.rappen) / 100

                AreaMark(
                    x: .value("Periode", label),
                    y: .value("Defizit", francs)
                )
                .interpolationMethod(.monotone)
                .foregroundStyle(
                    LinearGradient(
                        colors: [Theme.negative, Theme.negative.opacity(0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                LineMark(
                    x: .value("Periode", label),
                    y: .value("Defizit", francs)
                )
                // Monoton statt Catmull-Rom: geschwungen, aber ohne Ausschläge unter 0.
                .interpolationMethod(.monotone)
                .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                .foregroundStyle(Theme.negative)
                .accessibilityLabel(point.period.title())
                .accessibilityValue(MoneyFormat.spoken(point.rappen))
            }

            if let selectedPoint {
                RuleMark(x: .value("Periode", selectedPoint.period.shortTitle()))
                    .lineStyle(StrokeStyle(lineWidth: 1))
                    .foregroundStyle(Theme.textTertiary)

                PointMark(
                    x: .value("Periode", selectedPoint.period.shortTitle()),
                    y: .value("Defizit", Double(selectedPoint.rappen) / 100)
                )
                .symbolSize(90)
                .foregroundStyle(Theme.negative)
            }
        }
        .chartYScale(domain: 0...yMaximum)
        .chartXSelection(value: $selectedLabel)
        .chartYAxis {
            AxisMarks(position: .leading, values: .automatic(desiredCount: 3)) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(Theme.separator)
                AxisValueLabel {
                    if let francs = value.as(Double.self) {
                        Text("\(Int(francs.rounded()))")
                            .font(.caption2)
                            .foregroundStyle(Theme.textTertiary)
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks { _ in
                AxisValueLabel()
                    .font(.caption2)
                    .foregroundStyle(Theme.textSecondary)
            }
        }
        .accessibilityLabel("Verlauf vom Defizit \(String(period.budgetYear))")
    }

    @ViewBuilder
    private var footnote: some View {
        VStack(alignment: .leading, spacing: 4) {
            if current > 0 {
                if let daily = status.dailyWithCompensation {
                    Text("Zum Uusglyche: höchschtens \(MoneyFormat.chf(daily)) pro Tag bis zum 24.")
                } else if status.summary.remainingDays > 0 {
                    Text("Die Periode reicht nid für e ganze Uusglych – o ohni wyteri Usgabe blybe \(MoneyFormat.chf(-status.spendableAfterCompensation)) offe.")
                }
            }
            if period.next().startsBudgetYear {
                Text("Am 25.12. fangt ds Defizit wieder bi null a.")
            }
        }
        .font(.footnote)
        .monospacedDigit()
        .foregroundStyle(Theme.textSecondary)
    }
}
