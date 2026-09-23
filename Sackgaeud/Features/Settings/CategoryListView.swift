import SwiftData
import SwiftUI

/// Kategorien verwalten: umordnen, bearbeiten, neu, löschen (SPEC 3.2).
struct CategoryListView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \SpendingCategory.sortOrder) private var categories: [SpendingCategory]

    @State private var editing: CategoryEditorTarget?
    @State private var pendingDeletion: SpendingCategory?

    var body: some View {
        List {
            Section {
                ForEach(categories) { category in
                    Button {
                        editing = CategoryEditorTarget(category: category)
                    } label: {
                        HStack(spacing: 12) {
                            CategoryIcon(display: CategoryDisplay(category))
                            Text(category.name)
                                .foregroundStyle(Theme.textPrimary)
                            Spacer()
                            if category.isFallback {
                                Image(systemName: "lock")
                                    .font(.caption)
                                    .foregroundStyle(Theme.textTertiary)
                                    .accessibilityLabel("Cha nid glöscht wärde")
                            }
                        }
                    }
                    .buttonStyle(.plain)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        if !category.isFallback {
                            Button(role: .destructive) {
                                pendingDeletion = category
                            } label: {
                                Label("Lösche", systemImage: "trash")
                            }
                        }
                    }
                }
                .onMove(perform: move)
            } footer: {
                Text("„Diverses“ cha nid glöscht wärde: Dert lande d Buechige vo glöschte Kategorie.")
            }
            .listRowBackground(Theme.surface)
        }
        .listStyle(.insetGrouped)
        .themedList()
        .navigationTitle("Kategorie")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                EditButton()
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    editing = CategoryEditorTarget(category: nil)
                } label: {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Neui Kategorie")
            }
        }
        .sheet(item: $editing) { target in
            CategoryEditorView(category: target.category)
        }
        .confirmationDialog(
            deletionTitle,
            isPresented: Binding(
                get: { pendingDeletion != nil },
                set: { if !$0 { pendingDeletion = nil } }
            ),
            titleVisibility: .visible,
            presenting: pendingDeletion
        ) { category in
            Button("Lösche", role: .destructive) {
                BudgetRepository(context: context).delete(category)
                pendingDeletion = nil
            }
            Button("Abbräche", role: .cancel) {
                pendingDeletion = nil
            }
        } message: { category in
            Text(deletionMessage(for: category))
        }
    }

    private var deletionTitle: String {
        "„\(pendingDeletion?.name ?? "")“ lösche?"
    }

    private func deletionMessage(for category: SpendingCategory) -> String {
        switch category.expenseCount {
        case 0: return "Die Kategorie het keni Buechige."
        case 1: return "1 Buechig chunnt nach „Diverses“."
        default: return "\(category.expenseCount) Buechige chöme nach „Diverses“."
        }
    }

    private func move(from source: IndexSet, to destination: Int) {
        var reordered = categories
        reordered.move(fromOffsets: source, toOffset: destination)
        BudgetRepository(context: context).reorder(reordered)
    }
}

struct CategoryEditorTarget: Identifiable {
    let id = UUID()
    let category: SpendingCategory?
}

/// Name, Symbol und Farbe einer Kategorie.
struct CategoryEditorView: View {
    let category: SpendingCategory?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @State private var name: String
    @State private var symbol: String
    @State private var colorIndex: Int

    init(category: SpendingCategory?) {
        self.category = category
        _name = State(initialValue: category?.name ?? "")
        _symbol = State(initialValue: category?.symbol ?? Self.symbols[0])
        _colorIndex = State(initialValue: category?.colorIndex ?? 0)
    }

    /// Auswahl an passenden SF Symbols.
    static let symbols = [
        "cart", "basket", "fork.knife", "cup.and.saucer", "wineglass", "birthday.cake",
        "bag", "tshirt", "shoe", "gift", "book", "gamecontroller",
        "figure.hiking", "figure.run", "bicycle", "ticket", "music.note", "film",
        "tram", "car", "fuelpump", "airplane", "house", "wrench.and.screwdriver",
        "cross.case", "pills", "scissors", "pawprint", "leaf", "heart",
        "graduationcap", "iphone", "creditcard", "banknote", "sparkles", "ellipsis.circle"
    ]

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Name") {
                    TextField("z. B. Gschänk", text: $name)
                        .foregroundStyle(Theme.textPrimary)
                }
                .listRowBackground(Theme.surface)

                Section("Farb") {
                    HStack(spacing: 10) {
                        ForEach(Theme.categoryPalette.indices, id: \.self) { index in
                            Button {
                                colorIndex = index
                            } label: {
                                Circle()
                                    .fill(Theme.categoryColor(index))
                                    .frame(width: 30, height: 30)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white, lineWidth: index == colorIndex ? 3 : 0)
                                    )
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel("Farb \(index + 1)")
                            .accessibilityAddTraits(index == colorIndex ? .isSelected : [])
                        }
                    }
                    .padding(.vertical, 4)
                }
                .listRowBackground(Theme.surface)

                Section("Symbol") {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 44), spacing: 8)], spacing: 8) {
                        ForEach(Self.symbols, id: \.self) { symbolName in
                            Button {
                                symbol = symbolName
                            } label: {
                                Image(systemName: symbolName)
                                    .font(.title3)
                                    .frame(width: 44, height: 44)
                                    .foregroundStyle(symbolName == symbol ? Theme.categoryColor(colorIndex) : Theme.textSecondary)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                                            .fill(symbolName == symbol ? Theme.categoryColor(colorIndex).opacity(0.18) : Color.clear)
                                    )
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(symbolName)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .listRowBackground(Theme.surface)
            }
            .listStyle(.insetGrouped)
            .themedList()
            .navigationTitle(category == nil ? "Neui Kategorie" : "Kategorie bearbeite")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Abbräche") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Sichere", action: save)
                        .fontWeight(.semibold)
                        .disabled(trimmedName.isEmpty)
                }
            }
        }
    }

    private func save() {
        let repository = BudgetRepository(context: context)
        if let category {
            repository.update(category, name: trimmedName, symbol: symbol, colorIndex: colorIndex)
        } else {
            repository.addCategory(name: trimmedName, symbol: symbol, colorIndex: colorIndex)
        }
        dismiss()
    }
}
