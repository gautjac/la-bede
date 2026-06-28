import SwiftUI

/// An abstract token for an Image Playground generation style. Kept free of the
/// `ImagePlayground` framework (and its `@available` gating) so the data model
/// and the views can reason about styles without importing it; `PanelRenderer`
/// maps each token to a concrete `ImagePlaygroundStyle` at render time.
enum StyleKind: String, CaseIterable, Codable, Sendable {
    case illustration   // Apple built-in: colourful illustration
    case animation      // Apple built-in: soft 3D animated-film look
    case sketch         // Apple built-in: hand-drawn pencil / ink sketch
    case emoji          // Apple built-in: emoji-like
    case externalProvider // iOS 26+: free-form style via the connected provider
    case any            // iOS 27+: unified free-form style

    /// The built-in styles are always present whenever generation works; the
    /// free-form kinds need a connected provider (e.g. ChatGPT) to be enabled.
    var isFreeform: Bool { self == .externalProvider || self == .any }
}

/// A user-pickable art-style preset for a strip. Drives three things:
///  • which `ImagePlaygroundStyle` the renderer asks for (via `preferredKinds`),
///  • a rich free-form style prompt used when routed through a provider style,
///  • the swatch + placeholder palette so the choice is visible everywhere —
///    including the Simulator's hand-drawn fallback art.
struct StripStyle: Identifiable, Equatable, Hashable {
    let id: String
    /// French display name, e.g. "Aquarelle".
    let name: String
    /// One-line description for the picker.
    let tagline: String
    /// SF Symbol shown on the picker chip.
    let symbol: String
    /// The look, in words. Injected as a concept only when the resolved style is
    /// a free-form provider style (the built-in styles ignore style text).
    let freeformPrompt: String
    /// Ordered preference of generation styles; the renderer takes the first one
    /// the device actually offers.
    let preferredKinds: [StyleKind]
    /// Two-to-three tints that colour the procedural placeholder panels so even
    /// the no-AI fallback reflects the chosen style.
    let palette: [Color]

    /// True when the preset is meant to render through a free-form provider style
    /// (so the picker can hide it where no provider is connected).
    var needsProvider: Bool { preferredKinds.contains { $0.isFreeform } }

    /// A soft gradient for the picker chip's swatch.
    var swatch: LinearGradient {
        LinearGradient(colors: palette, startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

extension StripStyle {

    // MARK: Built-in-backed presets (always render real art when AI is on)

    static let bandeDessinee = StripStyle(
        id: "bd",
        name: "Bande dessinée",
        tagline: "Ligne claire, couleurs pop",
        symbol: "book.pages.fill",
        freeformPrompt: "clean ligne-claire bande-dessinée art, bold ink outlines, flat pop colours, halftone shading",
        preferredKinds: [.illustration, .animation, .sketch],
        palette: [Color(red: 0.75, green: 0.89, blue: 0.97),
                  Color(red: 1.0,  green: 0.88, blue: 0.66),
                  Color(red: 0.97, green: 0.78, blue: 0.81)]
    )

    static let dessinAnime = StripStyle(
        id: "anim",
        name: "Dessin animé",
        tagline: "Rondeur 3D, film d'animation",
        symbol: "movieclapper.fill",
        freeformPrompt: "soft 3D animated-film style, rounded friendly characters, warm cinematic lighting",
        preferredKinds: [.animation, .illustration, .sketch],
        palette: [Color(red: 0.78, green: 0.91, blue: 0.95),
                  Color(red: 0.85, green: 0.95, blue: 0.82),
                  Color(red: 0.99, green: 0.86, blue: 0.72)]
    )

    static let croquis = StripStyle(
        id: "sketch",
        name: "Croquis",
        tagline: "Crayon, fait main",
        symbol: "pencil.and.outline",
        freeformPrompt: "loose hand-drawn pencil sketch, expressive linework, light cross-hatching, sketchbook feel",
        preferredKinds: [.sketch, .illustration, .animation],
        palette: [Color(red: 0.93, green: 0.91, blue: 0.86),
                  Color(red: 0.86, green: 0.84, blue: 0.80),
                  Color(red: 0.97, green: 0.95, blue: 0.90)]
    )

    // MARK: Free-form presets (need a connected provider; richer looks)

    static let aquarelle = StripStyle(
        id: "watercolor",
        name: "Aquarelle",
        tagline: "Lavis doux, papier grain",
        symbol: "drop.fill",
        freeformPrompt: "loose watercolour painting, soft translucent washes, gentle colour bleeding, visible paper texture",
        preferredKinds: [.any, .externalProvider, .illustration],
        palette: [Color(red: 0.80, green: 0.90, blue: 0.93),
                  Color(red: 0.96, green: 0.85, blue: 0.88),
                  Color(red: 0.88, green: 0.92, blue: 0.83)]
    )

    static let huile = StripStyle(
        id: "oil",
        name: "Peinture à l'huile",
        tagline: "Coups de pinceau, classique",
        symbol: "paintpalette.fill",
        freeformPrompt: "rich oil painting, visible impasto brush strokes, warm classical palette, painterly depth",
        preferredKinds: [.any, .externalProvider, .illustration],
        palette: [Color(red: 0.85, green: 0.66, blue: 0.42),
                  Color(red: 0.66, green: 0.38, blue: 0.34),
                  Color(red: 0.92, green: 0.82, blue: 0.60)]
    )

    static let pixel = StripStyle(
        id: "pixel",
        name: "Pixel art",
        tagline: "Rétro 16-bit, jeu vidéo",
        symbol: "squareshape.split.3x3",
        freeformPrompt: "16-bit pixel-art sprite scene, crisp pixels, limited retro video-game palette, dithering",
        preferredKinds: [.any, .externalProvider, .illustration],
        palette: [Color(red: 0.45, green: 0.78, blue: 0.55),
                  Color(red: 0.55, green: 0.50, blue: 0.85),
                  Color(red: 0.97, green: 0.80, blue: 0.35)]
    )

    static let noir = StripStyle(
        id: "noir",
        name: "Noir",
        tagline: "Noir et blanc, ombres dures",
        symbol: "moon.stars.fill",
        freeformPrompt: "high-contrast black and white film-noir ink, dramatic shadows, graphic-novel inking",
        preferredKinds: [.any, .externalProvider, .sketch],
        palette: [Color(red: 0.82, green: 0.83, blue: 0.86),
                  Color(red: 0.55, green: 0.57, blue: 0.62),
                  Color(red: 0.90, green: 0.91, blue: 0.93)]
    )

    static let estampe = StripStyle(
        id: "popprint",
        name: "Estampe rétro",
        tagline: "Sérigraphie pop années 60",
        symbol: "circle.grid.3x3.fill",
        freeformPrompt: "1960s silkscreen pop-art print, bold flat spot colours, heavy Ben-Day halftone dots, Lichtenstein vibe",
        preferredKinds: [.any, .externalProvider, .illustration],
        palette: [Color(red: 0.95, green: 0.28, blue: 0.36),
                  Color(red: 0.97, green: 0.80, blue: 0.24),
                  Color(red: 0.23, green: 0.55, blue: 0.87)]
    )

    // MARK: Catalog

    /// Every preset, in picker order (built-ins first, then the richer looks).
    static let all: [StripStyle] = [
        bandeDessinee, dessinAnime, croquis,
        aquarelle, huile, pixel, noir, estampe,
    ]

    static let `default` = bandeDessinee

    /// Look up a preset by its stored id, falling back to the default.
    static func find(_ id: String) -> StripStyle {
        all.first { $0.id == id } ?? .default
    }
}
