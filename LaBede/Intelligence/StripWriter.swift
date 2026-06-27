import Foundation
import FoundationModels

/// Turns a short beat about the user's day into a three-panel comic *script*:
/// a title, a recurring character, a shared art style, and three (caption,
/// scene) panels. Prefers Apple's on-device Foundation Model (iOS 26+, guided
/// generation) and falls back to a deterministic local writer when the model
/// isn't available (Simulator / hardware without Apple Intelligence) so the
/// app is always usable.
@available(iOS 26.0, *)
@MainActor
final class StripWriter {

    /// Where a script came from — drives the UI provenance label.
    enum Source { case onDevice, local }

    struct Script {
        var title: String
        var character: String
        var style: String
        var panels: [(caption: String, scene: String)]
        var source: Source
    }

    // MARK: Guided-generation schema

    /// The whole three-panel script in one generation, so the model keeps the
    /// character and style coherent across panels.
    @Generable
    struct ComicScript {
        @Guide(description: "A short, punchy comic-strip title for the day, 2 to 5 words, in the user's language. No quotation marks.")
        var title: String

        @Guide(description: "One vivid sentence describing the single recurring main character (the storyteller's avatar): species or look, hair, clothing, one defining trait. This exact description is reused to draw every panel so the character must stay identical. Keep it concrete and visual.")
        var character: String

        @Guide(description: "One sentence naming a single consistent comic art style for the whole strip, e.g. 'bold ink outlines, flat pop colours, halftone shading, bande-dessinée look'. Reused for every panel.")
        var style: String

        @Guide(description: "Exactly three panels telling the beat as a tiny beginning-middle-end story.")
        var panels: [ComicPanel]
    }

    @Generable
    struct ComicPanel {
        @Guide(description: "A very short caption for the panel's caption box: max 8 words, in the user's language, present tense, a little witty.")
        var caption: String

        @Guide(description: "A vivid visual scene description for an image generator: what the recurring character is doing, the setting, the mood and one strong action or expression. One or two sentences. Do NOT restate the art style or re-describe the character's fixed look — those are added automatically.")
        var scene: String
    }

    var isOnDeviceAvailable: Bool {
        if case .available = SystemLanguageModel.default.availability { return true }
        return false
    }

    /// Why the model is unavailable, for a precise graceful message.
    var unavailabilityReason: String? {
        switch SystemLanguageModel.default.availability {
        case .available:
            return nil
        case .unavailable(.deviceNotEligible):
            return String(localized: "Cet appareil ne prend pas en charge Apple Intelligence.")
        case .unavailable(.appleIntelligenceNotEnabled):
            return String(localized: "Activez Apple Intelligence dans les Réglages.")
        case .unavailable(.modelNotReady):
            return String(localized: "Le modèle se télécharge encore. Réessayez bientôt.")
        case .unavailable:
            return String(localized: "Apple Intelligence n'est pas disponible pour l'instant.")
        }
    }

    func write(beat: String) async -> Script {
        let cleaned = beat.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return Self.localScript(for: cleaned) }

        if case .available = SystemLanguageModel.default.availability {
            do {
                let session = LanguageModelSession {
                    """
                    You are a witty bande-dessinée writer. Given a short note about
                    something that happened in someone's day, you turn it into a
                    three-panel comic strip: a title, ONE recurring main character
                    (the narrator's avatar), ONE consistent art style, and three
                    panels that tell it as a tiny beginning-middle-end story with a
                    little warmth or humour. Keep the same character and style across
                    all three panels. Answer in the same language as the note. Never
                    invent dark, violent, or inappropriate content; keep it light and
                    everyday.
                    """
                }
                let response = try await session.respond(to: cleaned, generating: ComicScript.self)
                let s = response.content
                var panels = s.panels.prefix(3).map { (caption: $0.caption, scene: $0.scene) }
                // The model occasionally returns fewer than three — top up locally
                // so the strip is always a full three-panel page.
                if panels.count < 3 {
                    let filler = Self.localScript(for: cleaned).panels
                    while panels.count < 3 { panels.append(filler[panels.count]) }
                }
                let title = s.title.trimmingCharacters(in: .whitespacesAndNewlines)
                return Script(
                    title: title.isEmpty ? Self.fallbackTitle(cleaned) : title,
                    character: s.character.trimmingCharacters(in: .whitespacesAndNewlines),
                    style: s.style.trimmingCharacters(in: .whitespacesAndNewlines),
                    panels: Array(panels),
                    source: .onDevice
                )
            } catch {
                Log.intel.error("On-device script failed: \(error.localizedDescription)")
            }
        }

        return Self.localScript(for: cleaned)
    }

    // MARK: Deterministic local fallback

    /// A real, usable three-panel script built without any model — so the app
    /// works on the Simulator and on non-AI hardware. It reuses the user's own
    /// words and a fixed friendly character so panels still feel cohesive.
    static func localScript(for beat: String) -> Script {
        let cleaned = beat.trimmingCharacters(in: .whitespacesAndNewlines)
        let subject = cleaned.isEmpty
            ? String(localized: "une journée ordinaire")
            : cleaned

        let character = String(localized: "Un petit personnage rond aux grands yeux, pull rayé rouge et blanc, toujours curieux.")
        let style = String(localized: "Traits d'encre épais, couleurs pop à plat, trame de points, look bande dessinée.")

        let p1 = (
            caption: String(localized: "Tout commence."),
            scene: String(localized: "Le personnage, songeur, au début de : \(subject).")
        )
        let p2 = (
            caption: String(localized: "Et là, ça se corse."),
            scene: String(localized: "En plein dans l'action : \(subject), avec une expression vive.")
        )
        let p3 = (
            caption: String(localized: "Fin de l'histoire."),
            scene: String(localized: "Le personnage, satisfait, repense à : \(subject).")
        )

        return Script(title: fallbackTitle(cleaned),
                      character: character,
                      style: style,
                      panels: [p1, p2, p3],
                      source: .local)
    }

    /// A tidy title from the beat's first few words.
    static func fallbackTitle(_ beat: String) -> String {
        let words = beat.split(whereSeparator: { $0 == " " || $0.isNewline })
        if words.isEmpty { return String(localized: "Ma journée") }
        let first = words.prefix(4).joined(separator: " ")
        return first.prefix(1).uppercased() + first.dropFirst()
    }
}
