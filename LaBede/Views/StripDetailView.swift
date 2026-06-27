import SwiftUI
import SwiftData
import ImagePlayground
import UIKit

/// Reread one strip full-screen: the beat that started it, the comic page, and
/// actions — share as PNG, pick a Genmoji mascot byline.
@available(iOS 26.0, *)
struct StripDetailView: View {
    @Bindable var strip: Strip
    @Environment(\.modelContext) private var context
    @Environment(\.colorScheme) private var scheme

    @State private var exportURL: URL?
    @State private var showMascotSheet = false

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                beatCard

                StripView(strip: strip)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(Theme.ink, lineWidth: 4)
                    )
                    .shadow(color: Theme.ink.opacity(0.85), radius: 0, x: 5, y: 7)

                actions
            }
            .padding(16)
        }
        .background(Theme.background(scheme))
        .navigationTitle(strip.title.isEmpty ? "Bédé" : strip.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if let url = exportURL {
                    ShareLink(item: url, preview: SharePreview(strip.title, image: Image(systemName: "photo")))
                } else {
                    Button {
                        prepareExport()
                    } label: { Image(systemName: "square.and.arrow.up") }
                }
            }
        }
        .imagePlaygroundSheet(
            isPresented: $showMascotSheet,
            concept: mascotConcept,
            onCompletion: { url in
                if let data = try? Data(contentsOf: url) { setMascot(data) }
            },
            onAdaptiveImageGlyphCreation: { glyph in
                setMascot(glyph.imageContent)
            }
        )
        .onAppear(perform: prepareExport)
    }

    private var beatCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Ce qui s'est passé", systemImage: "quote.opening")
                .font(Theme.caption(13))
                .foregroundStyle(Theme.pop)
            Text(strip.beat)
                .font(Theme.body(16))
                .foregroundStyle(Theme.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .comicPanel(fill: Theme.cream)
    }

    private var actions: some View {
        VStack(spacing: 12) {
            Button {
                showMascotSheet = true
            } label: {
                Label(strip.mascotPNG == nil ? "Choisir une mascotte (Genmoji)"
                                             : "Changer la mascotte",
                      systemImage: "face.smiling.inverse")
                    .font(Theme.caption(15))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.bordered)
            .tint(Theme.popBlue)

            if let url = exportURL {
                ShareLink(item: url,
                          preview: SharePreview(strip.title, image: Image(systemName: "photo"))) {
                    Label("Partager la planche", systemImage: "square.and.arrow.up")
                        .font(Theme.caption(15))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .tint(Theme.pop)
            }
        }
    }

    /// A short concept guiding the Genmoji/glyph toward the strip's character.
    private var mascotConcept: String {
        let c = strip.characterDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        return c.isEmpty ? strip.title : c
    }

    private func setMascot(_ data: Data) {
        strip.mascotPNG = data
        try? context.save()
        prepareExport()   // refresh the share image to include the new byline
    }

    private func prepareExport() {
        exportURL = StripExporter.exportURL(for: strip)
    }
}
