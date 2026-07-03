import SwiftUI

/// Lays out one strip as a real comic page: a hand-lettered title banner, three
/// stacked panels with bold ink borders and gutters, a caption box under each,
/// and a little mascot byline. This same view is what `ImageRenderer` exports
/// to PNG, so what you see is exactly what you share.
struct StripView: View {
    let strip: Strip
    /// When true, render at export fidelity (no live placeholders animating).
    var forExport: Bool = false

    var body: some View {
        VStack(spacing: 14) {
            titleBanner
            ForEach(Array(strip.panels.enumerated()), id: \.element.id) { index, panel in
                PanelCell(panel: panel, index: index, palette: strip.style.palette)
            }
            byline
        }
        .padding(18)
        .background(
            ZStack {
                Theme.page
                HalftoneField(color: Theme.pop, spacing: 18, dotRadius: 2.4, opacity: 0.16)
            }
        )
    }

    private var titleBanner: some View {
        HStack(spacing: 10) {
            Text(strip.title.isEmpty ? "Ma journée" : strip.title)
                .font(Theme.display(26))
                .foregroundStyle(Theme.cream)
                .lineLimit(2)
                .minimumScaleFactor(0.6)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(strip.createdAt, format: .dateTime.day().month(.abbreviated))
                .font(Theme.caption(13))
                .foregroundStyle(Theme.popYellow)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(
            ZStack {
                Theme.ink
                HalftoneField(color: Theme.popYellow, spacing: 12, dotRadius: 1.6, opacity: 0.18)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(Theme.ink, lineWidth: 4)
        )
    }

    private var byline: some View {
        HStack(spacing: 8) {
            if let png = strip.mascotPNG, let ui = UIImage(data: png) {
                Image(uiImage: ui)
                    .resizable().scaledToFit()
                    .frame(width: 26, height: 26)
            } else {
                Text("✦")
                    .font(Theme.display(18))
                    .foregroundStyle(Theme.pop)
            }
            Text("La Bédé")
                .font(Theme.caption(13))
                .foregroundStyle(Theme.ink.opacity(0.7))
            Spacer()
            Text(credit)
                .font(Theme.body(11))
                .foregroundStyle(Theme.ink.opacity(0.45))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(.horizontal, 6)
    }

    /// "Aquarelle · Flux" / "Croquis · esquisse".
    private var credit: String {
        let source = strip.source == .playground ? "Flux" : "esquisse"
        return "\(strip.style.name) · \(source)"
    }
}

/// One panel + its caption box.
struct PanelCell: View {
    let panel: Panel
    let index: Int
    /// The strip's style palette — colours the procedural placeholder fallback.
    var palette: [Color] = Theme.panelTints

    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                if let png = panel.imagePNG, let ui = UIImage(data: png) {
                    Image(uiImage: ui)
                        .resizable()
                        .scaledToFill()
                } else {
                    PlaceholderPanel(seed: panel.seed, tint: paletteTint)
                }
                // Panel number tab, comic style
                VStack {
                    HStack {
                        Text("\(index + 1)")
                            .font(Theme.display(14))
                            .foregroundStyle(Theme.cream)
                            .frame(width: 26, height: 26)
                            .background(Circle().fill(Theme.ink))
                            .padding(8)
                        Spacer()
                    }
                    Spacer()
                }
            }
            .frame(height: 200)
            .frame(maxWidth: .infinity)
            .clipped()

            // Caption box
            Text(panel.caption)
                .font(Theme.caption(15))
                .foregroundStyle(Theme.ink)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 12)
                .padding(.vertical, 9)
                .background(Theme.popYellow)
        }
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Theme.ink)
                .shadow(color: Theme.ink.opacity(0.85), radius: 0, x: 4, y: 5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Theme.ink, lineWidth: 4)
        )
    }

    /// This panel's tint from the strip's palette (safe for any palette length).
    private var paletteTint: Color {
        let tints = palette.isEmpty ? Theme.panelTints : palette
        return tints[((index % tints.count) + tints.count) % tints.count]
    }
}
