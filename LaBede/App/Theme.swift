import SwiftUI

/// La Bédé's loud comic-book palette and shared look. Bold ink, halftone dots,
/// pop primaries — the opposite of a calm paper app. Everything here is the
/// strip's visual signature, reused by the renderer and the export.
enum Theme {

    // MARK: Core ink + page

    /// Near-black comic ink for borders, gutters, lettering.
    static let ink = Color(red: 0.09, green: 0.08, blue: 0.07)
    /// The warm newsprint page the strips sit on.
    static let page = Color(red: 0.99, green: 0.93, blue: 0.78)
    /// A slightly deeper cream for cards on the page.
    static let cream = Color(red: 1.0, green: 0.96, blue: 0.86)

    // MARK: Pop accents

    static let pop = Color(red: 0.95, green: 0.28, blue: 0.36)      // hot comic red
    static let popYellow = Color(red: 0.97, green: 0.80, blue: 0.24) // burst yellow
    static let popBlue = Color(red: 0.23, green: 0.55, blue: 0.87)   // sky blue
    static let popTeal = Color(red: 0.18, green: 0.77, blue: 0.71)   // mint teal
    static let popPink = Color(red: 0.97, green: 0.62, blue: 0.70)   // bubblegum

    /// The rotating panel tints — gives every strip three distinct panels while
    /// staying in one cohesive comic palette.
    static let panelTints: [Color] = [
        Color(red: 0.75, green: 0.89, blue: 0.97),  // pale sky
        Color(red: 1.0,  green: 0.88, blue: 0.66),  // warm sand
        Color(red: 0.97, green: 0.78, blue: 0.81),  // dusty rose
        Color(red: 0.80, green: 0.92, blue: 0.83),  // soft mint
    ]

    static func panelTint(_ index: Int) -> Color {
        panelTints[((index % panelTints.count) + panelTints.count) % panelTints.count]
    }

    /// Page background that adapts to dark mode but keeps the comic warmth.
    static func background(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(red: 0.12, green: 0.11, blue: 0.10) : page
    }

    // MARK: Type — a punchy display face for titles/captions

    /// Heavy rounded display, evoking hand-lettered comic titles.
    static func display(_ size: CGFloat) -> Font {
        .system(size: size, weight: .black, design: .rounded)
    }
    static func caption(_ size: CGFloat) -> Font {
        .system(size: size, weight: .heavy, design: .rounded)
    }
    static func body(_ size: CGFloat) -> Font {
        .system(size: size, weight: .semibold, design: .rounded)
    }
}

// MARK: - Reusable comic-book view treatments

/// A bold ink panel border with a slight offset drop shadow — the signature
/// "sticker" look of every card in the app.
struct ComicPanel: ViewModifier {
    var fill: Color = Theme.cream
    var radius: CGFloat = 16
    var lineWidth: CGFloat = 4
    var shadow: Bool = true

    func body(content: Content) -> some View {
        content
            .background(
                // The shadow is cast by the shape only — NOT by `content` — so a
                // zero-blur "sticker" drop shadow never duplicates the text glyphs.
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .fill(fill)
                    .shadow(color: shadow ? Theme.ink.opacity(0.9) : .clear,
                            radius: 0, x: shadow ? 5 : 0, y: shadow ? 6 : 0)
            )
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(Theme.ink, lineWidth: lineWidth)
            )
    }
}

extension View {
    func comicPanel(fill: Color = Theme.cream, radius: CGFloat = 16,
                    lineWidth: CGFloat = 4, shadow: Bool = true) -> some View {
        modifier(ComicPanel(fill: fill, radius: radius, lineWidth: lineWidth, shadow: shadow))
    }
}

/// A halftone Ben-Day dot field, drawn with Canvas. Used behind hero areas and
/// inside placeholder panels to sell the comic look.
struct HalftoneField: View {
    var color: Color = Theme.pop
    var spacing: CGFloat = 16
    var dotRadius: CGFloat = 3
    var opacity: Double = 0.35

    var body: some View {
        Canvas { ctx, size in
            let dot = Path(ellipseIn: CGRect(x: 0, y: 0, width: dotRadius * 2, height: dotRadius * 2))
            var y: CGFloat = spacing / 2
            var row = 0
            while y < size.height + spacing {
                let xOffset: CGFloat = (row % 2 == 0) ? 0 : spacing / 2
                var x: CGFloat = xOffset + spacing / 2
                while x < size.width + spacing {
                    let placed = dot.offsetBy(dx: x - dotRadius, dy: y - dotRadius)
                    ctx.fill(placed, with: .color(color.opacity(opacity)))
                    x += spacing
                }
                y += spacing
                row += 1
            }
        }
        .allowsHitTesting(false)
    }
}
