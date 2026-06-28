import Foundation
import SwiftData

/// One comic strip in the Recueil — a single day's beat, drawn as three panels.
///
/// The strip persists everything needed to re-read it offline forever: the
/// original line the user jotted, the recurring character + style the model
/// invented (so the three panels feel like one strip), and each panel's caption,
/// image prompt, and — when Image Playground was available — the rendered PNG.
@Model
final class Strip {
    var id: UUID
    var createdAt: Date

    /// The 1–3 lines the user typed about their day.
    var beat: String

    /// A short title the model gave the strip, e.g. "Le café qui résiste".
    var title: String

    /// A one-line description of the recurring character, reused in every panel
    /// prompt so the protagonist looks consistent across the three drawings.
    var characterDescription: String

    /// A one-line art-style anchor (e.g. "bold ink linework, flat pop colours,
    /// halftone shading"), also fused into every panel prompt for consistency.
    var styleDescription: String

    /// The id of the `StripStyle` preset the user picked for this strip (e.g.
    /// "watercolor"). Defaulted inline so existing stores migrate automatically.
    var styleID: String = StripStyle.default.id

    /// How the panels were produced — drives the provenance label.
    /// "playground" = real Image Playground render, "placeholder" = hand-drawn
    /// fallback art so the app is always demoable.
    var renderSource: String

    /// The three panels, ordered. Stored inline (value type) on the model.
    var panels: [Panel]

    /// An optional Genmoji / glyph chosen as the strip's little mascot byline,
    /// stored as PNG data of the adaptive image glyph (or nil).
    @Attribute(.externalStorage) var mascotPNG: Data?

    init(beat: String,
         title: String,
         characterDescription: String,
         styleDescription: String,
         renderSource: RenderSource,
         panels: [Panel],
         styleID: String = StripStyle.default.id,
         createdAt: Date = Date()) {
        self.id = UUID()
        self.createdAt = createdAt
        self.beat = beat
        self.title = title
        self.characterDescription = characterDescription
        self.styleDescription = styleDescription
        self.styleID = styleID
        self.renderSource = renderSource.rawValue
        self.panels = panels
        self.mascotPNG = nil
    }

    var source: RenderSource {
        get { RenderSource(rawValue: renderSource) ?? .placeholder }
        set { renderSource = newValue.rawValue }
    }

    /// The art-style preset this strip was drawn in (falls back to the default
    /// if the stored id is unknown). Drives the placeholder palette and credit.
    var style: StripStyle {
        StripStyle.find(styleID)
    }

    /// True once every panel carries a real rendered image.
    var isFullyRendered: Bool {
        !panels.isEmpty && panels.allSatisfy { $0.imagePNG != nil }
    }
}

/// Where a strip's art came from.
enum RenderSource: String, Codable {
    case playground   // real Apple Intelligence Image Playground render
    case placeholder  // deterministic hand-drawn fallback art
}

/// A single comic panel: its caption, the prompt used to draw it, an optional
/// rendered PNG, and a deterministic seed so the placeholder art is stable.
struct Panel: Codable, Identifiable, Hashable {
    var id: UUID
    /// One short caption line shown in the panel's caption box.
    var caption: String
    /// The vivid scene prompt fed to Image Playground (or summarised for the
    /// placeholder).
    var prompt: String
    /// Rendered PNG bytes, when available. nil → draw the placeholder.
    var imagePNG: Data?
    /// Stable per-panel seed for the procedural placeholder so it never reshuffles.
    var seed: Int

    init(caption: String, prompt: String, imagePNG: Data? = nil, seed: Int? = nil) {
        self.id = UUID()
        self.caption = caption
        self.prompt = prompt
        self.imagePNG = imagePNG
        // Derive a stable seed from the prompt text when none is supplied.
        self.seed = seed ?? abs(prompt.hashValue == Int.min ? 0 : prompt.hashValue)
    }
}

extension Array where Element == Strip {
    /// Newest first — the Recueil reads like a diary, latest day on top.
    var newestFirst: [Strip] {
        sorted { $0.createdAt > $1.createdAt }
    }
}
