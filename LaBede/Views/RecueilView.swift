import SwiftUI
import SwiftData

/// The Recueil — every strip you've kept, newest first, as a stack of comic
/// pages you can reread, share, or delete.
@available(iOS 26.0, *)
struct RecueilView: View {
    @Environment(\.colorScheme) private var scheme
    @Query(sort: \Strip.createdAt, order: .reverse) private var strips: [Strip]
    @Environment(\.modelContext) private var context

    var body: some View {
        NavigationStack {
            Group {
                if strips.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVStack(spacing: 22) {
                            ForEach(strips) { strip in
                                NavigationLink {
                                    StripDetailView(strip: strip)
                                } label: {
                                    StripCard(strip: strip)
                                }
                                .buttonStyle(.plain)
                                .contextMenu {
                                    Button(role: .destructive) {
                                        delete(strip)
                                    } label: {
                                        Label("Supprimer", systemImage: "trash")
                                    }
                                }
                            }
                        }
                        .padding(16)
                    }
                }
            }
            .background(Theme.background(scheme))
            .navigationTitle("Recueil")
        }
    }

    private var emptyState: some View {
        VStack(spacing: 18) {
            ZStack {
                HalftoneField(color: Theme.pop, spacing: 22, dotRadius: 3, opacity: 0.25)
                Image(systemName: "books.vertical.fill")
                    .font(.system(size: 56, weight: .black))
                    .foregroundStyle(Theme.pop)
            }
            .frame(width: 140, height: 140)
            .clipShape(Circle())
            .overlay(Circle().strokeBorder(Theme.ink, lineWidth: 4))

            Text("Le Recueil est vide")
                .font(Theme.display(22))
                .foregroundStyle(Theme.ink)
            Text("Va dans « Aujourd'hui » et dessine ta première journée.")
                .font(Theme.body(15))
                .foregroundStyle(Theme.ink.opacity(0.65))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func delete(_ strip: Strip) {
        context.delete(strip)
        try? context.save()
    }
}

/// A compact preview card for the list: the strip itself, slightly inset.
@available(iOS 26.0, *)
struct StripCard: View {
    let strip: Strip

    var body: some View {
        StripView(strip: strip)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(Theme.ink, lineWidth: 4)
            )
            .shadow(color: Theme.ink.opacity(0.85), radius: 0, x: 5, y: 7)
    }
}
