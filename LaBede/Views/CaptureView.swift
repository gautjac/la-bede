import SwiftUI
import SwiftData

/// "Aujourd'hui" — jot a beat, watch it become a three-panel strip, save it.
@available(iOS 26.0, *)
struct CaptureView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.colorScheme) private var scheme
    @FocusState private var editing: Bool

    @State private var studio = StripStudio()
    @State private var beat: String = ""
    @State private var savedStrip: Strip?
    @State private var showSavedToast = false
    /// Remembered between launches so the last look stays selected.
    @AppStorage("lastStyleID") private var selectedStyleID = StripStyle.default.id

    /// Built-in presets always show; free-form presets appear only once the
    /// device probe confirms a provider is connected.
    private var visiblePresets: [StripStyle] {
        StripStyle.all.filter { !$0.needsProvider || studio.canRenderTrueStyle($0) }
    }

    private var selectedStyle: StripStyle { StripStyle.find(selectedStyleID) }

    private let prompts = [
        "Le café a débordé pendant que je répondais à un courriel…",
        "On a marché jusqu'au fleuve, le vent était bête.",
        "Première prise réussie au premier essai, miracle.",
        "J'ai retrouvé une vieille cassette de mon père.",
    ]
    @State private var placeholderPrompt = "Raconte un moment de ta journée…"

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if !studio.isImageGenAvailable {
                        availabilityBanner
                    }

                    editorCard

                    if !studio.isWorking {
                        StylePicker(presets: visiblePresets, selectedID: $selectedStyleID)
                            .padding(.horizontal, 2)
                    }

                    actionButton

                    if studio.isWorking {
                        progressCard
                    }

                    if let strip = studio.draft, studio.isWorking || studio.phase == .finished {
                        livePreview(strip)
                    }
                }
                .padding(16)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Theme.background(scheme))
            .navigationTitle("La Bédé")
            .navigationBarTitleDisplayMode(.large)
            .overlay(alignment: .bottom) {
                if showSavedToast { savedToast }
            }
            .onAppear {
                placeholderPrompt = prompts.randomElement() ?? placeholderPrompt
            }
            .task {
                // Find out which styles this device can really generate, so the
                // free-form presets only appear where they'll work.
                await studio.probeStyles()
                if !visiblePresets.contains(where: { $0.id == selectedStyleID }) {
                    selectedStyleID = StripStyle.default.id
                }
            }
        }
    }

    // MARK: Editor

    private var editorCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Une, deux, trois lignes sur ta journée.")
                .font(Theme.body(15))
                .foregroundStyle(Theme.ink.opacity(0.65))

            ZStack(alignment: .topLeading) {
                if beat.isEmpty {
                    Text(placeholderPrompt)
                        .font(Theme.body(17))
                        .foregroundStyle(Theme.ink.opacity(0.35))
                        .padding(.top, 8)
                        .padding(.horizontal, 5)
                }
                TextEditor(text: $beat)
                    .font(Theme.body(17))
                    .foregroundStyle(Theme.ink)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 110)
                    .focused($editing)
            }
        }
        .padding(14)
        .comicPanel(fill: Theme.cream)
        .padding(.horizontal, 2)
    }

    private var actionButton: some View {
        Button {
            editing = false
            startDrawing()
        } label: {
            HStack(spacing: 10) {
                if studio.isWorking {
                    ProgressView().tint(Theme.cream)
                } else {
                    Image(systemName: "wand.and.stars")
                }
                Text(studio.isWorking ? "Ça dessine…" : "Dessine ma journée")
                    .font(Theme.display(19))
            }
            .foregroundStyle(Theme.cream)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Theme.pop)
                    .overlay(
                        HalftoneField(color: .white, spacing: 14, dotRadius: 1.6, opacity: 0.14)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    )
                    .shadow(color: Theme.ink.opacity(0.85), radius: 0, x: 5, y: 6)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(Theme.ink, lineWidth: 4)
            )
        }
        .disabled(beat.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || studio.isWorking)
        .opacity(beat.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.55 : 1)
        .padding(.horizontal, 2)
    }

    // MARK: Progress

    private var progressCard: some View {
        VStack(spacing: 8) {
            switch studio.phase {
            case .writing:
                Label("Le scénario s'écrit…", systemImage: "text.book.closed")
                    .font(Theme.caption(15))
            case let .rendering(done, total):
                Label("Panneau \(done) sur \(total) qui se dessine…",
                      systemImage: "paintbrush.pointed.fill")
                    .font(Theme.caption(15))
                ProgressView(value: Double(done), total: Double(total))
                    .tint(Theme.pop)
            default:
                EmptyView()
            }
        }
        .foregroundStyle(Theme.ink)
        .frame(maxWidth: .infinity)
        .padding(14)
        .comicPanel(fill: Theme.popYellow.opacity(0.55))
        .padding(.horizontal, 2)
    }

    // MARK: Live preview + save

    @ViewBuilder
    private func livePreview(_ strip: Strip) -> some View {
        VStack(spacing: 14) {
            StripView(strip: strip)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(Theme.ink, lineWidth: 4)
                )
                .shadow(color: Theme.ink.opacity(0.3), radius: 10, y: 6)

            if studio.phase == .finished {
                HStack(spacing: 12) {
                    Button(role: .destructive) {
                        studio.reset()
                    } label: {
                        Label("Recommencer", systemImage: "arrow.counterclockwise")
                            .font(Theme.caption(15))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.bordered)
                    .tint(Theme.ink)

                    Button {
                        save(strip)
                    } label: {
                        Label("Garder dans le Recueil", systemImage: "tray.and.arrow.down.fill")
                            .font(Theme.caption(15))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Theme.pop)
                }
                .padding(.horizontal, 2)
            }
        }
    }

    private var availabilityBanner: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "sparkles")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(Theme.pop)
            VStack(alignment: .leading, spacing: 4) {
                Text("La Bédé adore Apple Intelligence")
                    .font(Theme.caption(15))
                    .fixedSize(horizontal: false, vertical: true)
                Text(studio.unavailabilityReason
                     ?? "La génération d'images n'est pas disponible ici — La Bédé dessine quand même de jolies esquisses.")
                    .font(Theme.body(13))
                    .foregroundStyle(Theme.ink.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .comicPanel(fill: Theme.popBlue.opacity(0.18))
        .padding(.horizontal, 2)
    }

    private var savedToast: some View {
        Label("Gardée dans le Recueil !", systemImage: "checkmark.seal.fill")
            .font(Theme.caption(15))
            .foregroundStyle(Theme.cream)
            .padding(.horizontal, 18).padding(.vertical, 12)
            .background(
                Capsule().fill(Theme.popTeal)
                    .shadow(color: Theme.ink.opacity(0.6), radius: 0, x: 3, y: 4)
            )
            .overlay(Capsule().strokeBorder(Theme.ink, lineWidth: 3))
            .padding(.bottom, 24)
            .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    // MARK: Actions

    private func startDrawing() {
        let text = beat
        let style = selectedStyle
        Task {
            _ = await studio.makeStrip(from: text, style: style)
        }
    }

    private func save(_ strip: Strip) {
        context.insert(strip)
        do {
            try context.save()
            Log.store.info("Saved strip \(strip.id.uuidString)")
        } catch {
            Log.store.error("Save failed: \(error.localizedDescription)")
        }
        savedStrip = strip
        beat = ""
        studio.reset()
        withAnimation(.spring) { showSavedToast = true }
        Task {
            try? await Task.sleep(for: .seconds(2))
            withAnimation { showSavedToast = false }
        }
    }
}
