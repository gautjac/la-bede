import SwiftUI

/// Réglages: the Fal.ai API key (stored in the Keychain) that lets La Bédé draw
/// real diffusion-model panels, plus the quality/speed model choice.
@available(iOS 26.0, *)
struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme

    @State private var key: String = Secrets.falKey ?? ""
    @State private var saved = false
    @AppStorage("falModel") private var falModel = FalClient.Model.fluxDev.rawValue

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    keyCard
                    modelCard
                    helpCard
                }
                .padding(16)
            }
            .background(Theme.background(scheme))
            .navigationTitle("Réglages")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("OK") { save(); dismiss() }
                        .font(Theme.caption(15))
                        .tint(Theme.pop)
                }
            }
        }
    }

    private var keyCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Clé Fal.ai", systemImage: "key.fill")
                .font(Theme.caption(15))
                .foregroundStyle(Theme.pop)
            Text("La Bédé dessine les cases avec un vrai modèle de diffusion (Flux) via Fal.ai. Colle ta clé — elle reste dans le trousseau de l'appareil.")
                .font(Theme.body(13))
                .foregroundStyle(Theme.ink.opacity(0.7))
                .fixedSize(horizontal: false, vertical: true)

            SecureField("xxxxxxxx-…:…", text: $key)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .font(.system(size: 14, design: .monospaced))
                .padding(12)
                .background(RoundedRectangle(cornerRadius: 10).fill(Theme.cream))
                .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Theme.ink.opacity(0.4), lineWidth: 2))

            HStack {
                if Secrets.hasFalKey {
                    Label("Clé enregistrée", systemImage: "checkmark.seal.fill")
                        .font(Theme.body(12))
                        .foregroundStyle(Theme.popTeal)
                }
                Spacer()
                if !key.isEmpty {
                    Button(role: .destructive) {
                        key = ""
                        Secrets.falKey = nil
                    } label: {
                        Label("Effacer", systemImage: "trash").font(Theme.body(12))
                    }
                    .tint(Theme.pop)
                }
            }
        }
        .padding(14)
        .comicPanel(fill: Theme.cream)
    }

    private var modelCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Modèle", systemImage: "slider.horizontal.3")
                .font(Theme.caption(15))
                .foregroundStyle(Theme.popBlue)
            Picker("Modèle", selection: $falModel) {
                ForEach(FalClient.Model.allCases, id: \.rawValue) { model in
                    Text(model.label).tag(model.rawValue)
                }
            }
            .pickerStyle(.segmented)
            Text("« Qualité » dessine de plus belles cases ; « Rapide » va plus vite. Trois cases par planche.")
                .font(Theme.body(12))
                .foregroundStyle(Theme.ink.opacity(0.6))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .comicPanel(fill: Theme.cream)
    }

    private var helpCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Où trouver la clé", systemImage: "questionmark.circle")
                .font(Theme.caption(13))
                .foregroundStyle(Theme.ink.opacity(0.6))
            Text("Crée une clé API sur fal.ai/dashboard/keys, puis colle-la ici. Chaque case générée consomme un peu de crédit Fal.")
                .font(Theme.body(12))
                .foregroundStyle(Theme.ink.opacity(0.6))
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .comicPanel(fill: Theme.popYellow.opacity(0.35))
    }

    private func save() {
        Secrets.falKey = key
        saved = true
    }
}
