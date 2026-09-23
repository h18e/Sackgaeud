import SwiftData
import SwiftUI

/// Erster Start: nur der Betrag (SPEC 4.1). Die Periode ist fix vom 25. bis 24.
struct OnboardingView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.today) private var today
    @State private var amountText = ""
    @FocusState private var amountFocused: Bool

    private var amountRappen: Int? { MoneyFormat.parse(amountText) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Image(systemName: "banknote")
                        .font(.system(size: 40))
                        .foregroundStyle(Theme.accent)
                    Text("Sali!")
                        .font(.largeTitle.bold())
                        .foregroundStyle(Theme.textPrimary)
                    Text("Sackgäud zeigt dr jederzyt, wie vüu du bis zum nächschte 25. no chasch usgäh.")
                        .foregroundStyle(Theme.textSecondary)
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Wie vüu hesch pro Monet zur fryje Verfüegig?")
                        .font(.headline)
                        .foregroundStyle(Theme.textPrimary)
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text("CHF")
                            .font(.title2)
                            .foregroundStyle(Theme.textSecondary)
                        TextField("1500", text: $amountText)
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                            .keyboardType(.decimalPad)
                            .focused($amountFocused)
                            .foregroundStyle(Theme.textPrimary)
                            .accessibilityLabel("Betrag pro Monet i Franke")
                    }
                    .card()
                    Text("Fixchöschte ghöre nid dry – nume das, wo nachhär für di säuber blibt. E Periode louft geng vom 25. bis zum 24.")
                        .font(.footnote)
                        .foregroundStyle(Theme.textSecondary)
                }

                Button {
                    guard let amountRappen else { return }
                    BudgetRepository(context: context).completeOnboarding(amountRappen: amountRappen, today: today)
                } label: {
                    Text("Los")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                }
                .buttonStyle(.borderedProminent)
                .tint(Theme.accent)
                .disabled(amountRappen == nil)
            }
            .padding(20)
            .padding(.top, 24)
        }
        .scrollDismissesKeyboard(.interactively)
        .screenBackground()
        .onAppear { amountFocused = true }
    }
}
