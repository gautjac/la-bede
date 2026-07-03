import SwiftUI

/// A user-pickable art-style preset for a strip. With a real diffusion model
/// drawing the panels, a preset is simply a name + a style prompt fragment that
/// is appended to every panel's prompt, plus a swatch and a placeholder palette
/// (used for the offline fallback art). Every preset works on every device — no
/// provider gating.
struct StripStyle: Identifiable, Equatable, Hashable {
    let id: String
    /// French display name, e.g. "Aquarelle".
    let name: String
    /// One-line description for the picker.
    let tagline: String
    /// SF Symbol shown on the picker chip.
    let symbol: String
    /// The look, in words — appended to every panel prompt so the whole strip
    /// shares one consistent art style.
    let stylePrompt: String
    /// Two-to-three tints that colour the procedural placeholder panels so even
    /// the offline fallback reflects the chosen style.
    let palette: [Color]

    /// A soft gradient for the picker chip's swatch.
    var swatch: LinearGradient {
        LinearGradient(colors: palette, startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

extension StripStyle {

    static let bandeDessinee = StripStyle(
        id: "bd",
        name: "Bande dessinée",
        tagline: "Ligne claire, couleurs pop",
        symbol: "book.pages.fill",
        stylePrompt: "clean ligne-claire bande-dessinée comic art, bold black ink outlines, flat vibrant pop colours, subtle halftone shading, Franco-Belgian comic style",
        palette: [Color(red: 0.75, green: 0.89, blue: 0.97),
                  Color(red: 1.0,  green: 0.88, blue: 0.66),
                  Color(red: 0.97, green: 0.78, blue: 0.81)]
    )

    static let dessinAnime = StripStyle(
        id: "anim",
        name: "Dessin animé",
        tagline: "Rondeur 3D, film d'animation",
        symbol: "movieclapper.fill",
        stylePrompt: "modern 3D animated film still, soft rounded friendly character design, warm cinematic lighting, smooth shading, Pixar-like render",
        palette: [Color(red: 0.78, green: 0.91, blue: 0.95),
                  Color(red: 0.85, green: 0.95, blue: 0.82),
                  Color(red: 0.99, green: 0.86, blue: 0.72)]
    )

    static let croquis = StripStyle(
        id: "sketch",
        name: "Croquis",
        tagline: "Crayon, fait main",
        symbol: "pencil.and.outline",
        stylePrompt: "loose hand-drawn pencil sketch, expressive graphite linework, light cross-hatching, sketchbook page, monochrome with a touch of colour",
        palette: [Color(red: 0.93, green: 0.91, blue: 0.86),
                  Color(red: 0.86, green: 0.84, blue: 0.80),
                  Color(red: 0.97, green: 0.95, blue: 0.90)]
    )

    static let aquarelle = StripStyle(
        id: "watercolor",
        name: "Aquarelle",
        tagline: "Lavis doux, papier grain",
        symbol: "drop.fill",
        stylePrompt: "loose watercolour painting, soft translucent washes, gentle colour bleeding, visible cold-press paper texture, delicate ink linework",
        palette: [Color(red: 0.80, green: 0.90, blue: 0.93),
                  Color(red: 0.96, green: 0.85, blue: 0.88),
                  Color(red: 0.88, green: 0.92, blue: 0.83)]
    )

    static let huile = StripStyle(
        id: "oil",
        name: "Peinture à l'huile",
        tagline: "Coups de pinceau, classique",
        symbol: "paintpalette.fill",
        stylePrompt: "rich oil painting, visible impasto brush strokes, warm classical palette, painterly depth and texture",
        palette: [Color(red: 0.85, green: 0.66, blue: 0.42),
                  Color(red: 0.66, green: 0.38, blue: 0.34),
                  Color(red: 0.92, green: 0.82, blue: 0.60)]
    )

    static let pixel = StripStyle(
        id: "pixel",
        name: "Pixel art",
        tagline: "Rétro 16-bit, jeu vidéo",
        symbol: "squareshape.split.3x3",
        stylePrompt: "16-bit pixel-art scene, crisp pixels, limited retro video-game palette, dithering, isometric game sprite look",
        palette: [Color(red: 0.45, green: 0.78, blue: 0.55),
                  Color(red: 0.55, green: 0.50, blue: 0.85),
                  Color(red: 0.97, green: 0.80, blue: 0.35)]
    )

    static let noir = StripStyle(
        id: "noir",
        name: "Noir",
        tagline: "Noir et blanc, ombres dures",
        symbol: "moon.stars.fill",
        stylePrompt: "high-contrast black and white film-noir ink illustration, dramatic chiaroscuro shadows, graphic-novel inking, moody",
        palette: [Color(red: 0.82, green: 0.83, blue: 0.86),
                  Color(red: 0.55, green: 0.57, blue: 0.62),
                  Color(red: 0.90, green: 0.91, blue: 0.93)]
    )

    static let estampe = StripStyle(
        id: "popprint",
        name: "Estampe rétro",
        tagline: "Sérigraphie pop années 60",
        symbol: "circle.grid.3x3.fill",
        stylePrompt: "1960s silkscreen pop-art print, bold flat spot colours, heavy Ben-Day halftone dots, Roy Lichtenstein vibe",
        palette: [Color(red: 0.95, green: 0.28, blue: 0.36),
                  Color(red: 0.97, green: 0.80, blue: 0.24),
                  Color(red: 0.23, green: 0.55, blue: 0.87)]
    )

    // MARK: Catalog

    /// Every preset, in picker order.
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
