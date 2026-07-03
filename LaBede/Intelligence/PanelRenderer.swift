import Foundation
import SwiftUI

/// Draws comic panels with a real text-to-image diffusion model via `FalClient`.
///
/// Apple removed the headless `ImageCreator` API in iOS 27, and its output was
/// loose and off-prompt anyway. A diffusion model (Flux) follows the sentence,
/// honours the chosen art style, and — by holding the seed constant across a
/// strip's three panels plus repeating the character description — keeps the
/// recurring character coherent.
enum PanelRenderer {

    /// Image generation is configured once the user has added a Fal.ai key.
    static var isConfigured: Bool { Secrets.hasFalKey }

    /// The Flux model chosen in Settings (defaults to the quality variant).
    static var selectedModel: FalClient.Model {
        let raw = UserDefaults.standard.string(forKey: "falModel")
        return FalClient.Model(rawValue: raw ?? "") ?? .fluxDev
    }

    // MARK: Prompt composition (pure + testable)

    /// Build the full diffusion prompt for one panel: the scene the user lived,
    /// the recurring character, the strip's art style, and guards that keep the
    /// panel clean (one panel, and no garbled generated text — we add real
    /// captions ourselves).
    static func composePrompt(scene: String, character: String, stylePrompt: String) -> String {
        var parts: [String] = []
        let s = scene.trimmingCharacters(in: .whitespacesAndNewlines)
        if !s.isEmpty { parts.append(s) }
        let c = character.trimmingCharacters(in: .whitespacesAndNewlines)
        if !c.isEmpty { parts.append(c) }
        let style = stylePrompt.trimmingCharacters(in: .whitespacesAndNewlines)
        if !style.isEmpty { parts.append(style) }
        parts.append("single comic book panel, full scene, no text, no speech bubbles, no lettering, no border")
        return parts.joined(separator: ". ")
    }

    // MARK: Render

    /// The outcome of rendering one panel: the PNG (on success) and, on failure,
    /// a short reason + raw debug detail so the UI can explain a fallback instead
    /// of silently dropping to placeholder art.
    struct RenderResult {
        let data: Data?
        let failureReason: String?
        let debug: String?
        var succeeded: Bool { data != nil }

        static func ok(_ data: Data) -> RenderResult { .init(data: data, failureReason: nil, debug: nil) }
        static func failed(_ reason: String, debug: String? = nil) -> RenderResult {
            .init(data: nil, failureReason: reason, debug: debug)
        }
    }

    /// Render one panel in the strip's chosen style. `seed` is shared across the
    /// strip's panels for character/style coherence.
    static func render(scene: String,
                       character: String,
                       style preset: StripStyle,
                       seed: Int) async -> RenderResult {
        guard let key = Secrets.falKey, !key.isEmpty else {
            return .failed("Ajoute ta clé Fal.ai dans les réglages pour dessiner les images.",
                           debug: "no-fal-key")
        }
        let prompt = composePrompt(scene: scene, character: character, stylePrompt: preset.stylePrompt)
        let client = FalClient(apiKey: key, model: selectedModel)
        do {
            let data = try await client.generateImage(prompt: prompt, seed: seed)
            return .ok(data)
        } catch {
            let reason = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            let dbg = "model=\(selectedModel.rawValue); \(String(describing: error))"
            Log.render.error("Fal render failed: \(dbg)")
            return .failed(reason, debug: dbg)
        }
    }
}
