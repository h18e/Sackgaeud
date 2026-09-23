import SwiftData
import SwiftUI

/// Einstellungen (SPEC 4.5): Betrag, Kategorien, Face ID, Über.
struct SettingsView: View {
    @Environment(\.today) private var today
    @Environment(AppLock.self) private var appLock
    @Query private var amounts: [BudgetAmount]

    private var currentAmount: Int? {
        BudgetMath.amount(for: BudgetPeriod(containing: today), in: amounts.map(\.setting))
    }

    var body: some View {
        List {
            Section {
                NavigationLink {
                    AmountSettingView()
                } label: {
                    LabeledValueRow(label: "Betrag pro Periode") {
                        Text(currentAmount.map(MoneyFormat.chf) ?? "–")
                            .monospacedDigit()
                            .foregroundStyle(Theme.textPrimary)
                    }
                }
                NavigationLink {
                    CategoryListView()
                } label: {
                    Text("Kategorie")
                }
            } footer: {
                Text("E Periode louft geng vom 25. bis zum 24.")
            }
            .listRowBackground(Theme.surface)

            Section {
                Toggle("Mit Face ID sperre", isOn: Binding(
                    get: { appLock.isEnabled },
                    set: { newValue in Task { await appLock.setEnabled(newValue) } }
                ))
                .tint(Theme.accent)
            } footer: {
                Text("Bim Starte und bim Zrüggcho i d App fragt Sackgäud nach Face ID. S Widget zeigt de es Schloss statt em Betrag.")
            }
            .listRowBackground(Theme.surface)

            Section("Über") {
                LabeledValueRow(label: "Version") {
                    Text(Self.version)
                        .foregroundStyle(Theme.textPrimary)
                }
                VStack(alignment: .leading, spacing: 6) {
                    Text("Dateschutz")
                        .foregroundStyle(Theme.textPrimary)
                    Text("Aui Date blibe uf dym Grät und i dyre private iCloud. Kei Server, kei Wärbig, kei Tracking.")
                        .font(.footnote)
                        .foregroundStyle(Theme.textSecondary)
                }
                .padding(.vertical, 2)
            }
            .listRowBackground(Theme.surface)

            #if DEBUG
            DeveloperSection()
                .listRowBackground(Theme.surface)
            #endif
        }
        .listStyle(.insetGrouped)
        .themedList()
        .navigationTitle("Istellige")
    }

    private static var version: String {
        let info = Bundle.main.infoDictionary
        let short = info?["CFBundleShortVersionString"] as? String ?? "?"
        let build = info?["CFBundleVersion"] as? String ?? "?"
        return "\(short) (\(build))"
    }
}

/// Betrag pro Periode ändern. Gilt ab sofort für die laufende Periode; vergangene
/// Perioden behalten ihren Betrag (SPEC 2.2).
struct AmountSettingView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(\.today) private var today
    @Query private var amounts: [BudgetAmount]

    @State private var amountText = ""
    @State private var didLoad = false
    @FocusState private var focused: Bool

    private var period: BudgetPeriod { BudgetPeriod(containing: today) }
    private var amountRappen: Int? { MoneyFormat.parse(amountText) }

    var body: some View {
        List {
            Section {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("CHF")
                        .foregroundStyle(Theme.textSecondary)
                    TextField("1500", text: $amountText)
                        .font(.title2.weight(.semibold))
                        .keyboardType(.decimalPad)
                        .focused($focused)
                        .accessibilityLabel("Betrag pro Periode i Franke")
                }
            } footer: {
                Text("Gilt ab sofort für d laufendi Periode (\(period.title())). Vergangeni Periode bhalte ihre Betrag.")
            }
            .listRowBackground(Theme.surface)
        }
        .listStyle(.insetGrouped)
        .themedList()
        .navigationTitle("Betrag")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Sichere") {
                    guard let amountRappen else { return }
                    BudgetRepository(context: context).setAmount(amountRappen, today: today)
                    dismiss()
                }
                .fontWeight(.semibold)
                .disabled(amountRappen == nil)
            }
        }
        .onAppear {
            guard !didLoad else { return }
            didLoad = true
            if let current = BudgetMath.amount(for: period, in: amounts.map(\.setting)) {
                amountText = MoneyFormat.inputText(current)
            }
            focused = true
        }
    }
}

#if DEBUG
/// Nur in Debug-Builds: Beispieldaten zum Ausprobieren.
private struct DeveloperSection: View {
    @Environment(\.modelContext) private var context
    @Environment(\.today) private var today
    @Query private var categories: [SpendingCategory]

    var body: some View {
        Section("Entwicklung") {
            Button("Beispiel-Buchungen erzeugen (3 Perioden)") {
                let repository = BudgetRepository(context: context)
                let calendar = Calendar.current
                for dayOffset in 0..<85 where dayOffset % 2 == 0 {
                    guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }
                    repository.addExpense(
                        amountRappen: Int.random(in: 350...6500),
                        date: date,
                        category: categories.randomElement()
                    )
                }
            }
        }
    }
}
#endif
