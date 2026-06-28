import SwiftUI

/// A horizontal rail of art-style preset chips. Picking one sets the look for
/// the next strip — both the real Image Playground render and the hand-drawn
/// placeholder palette.
struct StylePicker: View {
    let presets: [StripStyle]
    @Binding var selectedID: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Le style du jour")
                .font(Theme.caption(13))
                .foregroundStyle(Theme.ink.opacity(0.55))
                .padding(.horizontal, 4)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(presets) { preset in
                        StyleChip(preset: preset, selected: preset.id == selectedID)
                            .onTapGesture {
                                withAnimation(.snappy(duration: 0.18)) { selectedID = preset.id }
                            }
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 4)
            }
        }
    }
}

private struct StyleChip: View {
    let preset: StripStyle
    let selected: Bool

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(preset.swatch)
                    .overlay(
                        HalftoneField(color: .white, spacing: 11, dotRadius: 1.3, opacity: 0.22)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    )
                Image(systemName: preset.symbol)
                    .font(.system(size: 24, weight: .black))
                    .foregroundStyle(Theme.ink)
                    .shadow(color: .white.opacity(0.5), radius: 0, x: 1, y: 1)
                if selected {
                    VStack {
                        HStack {
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(Theme.cream, Theme.pop)
                                .padding(5)
                        }
                        Spacer()
                    }
                }
            }
            .frame(width: 78, height: 78)
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Theme.ink, lineWidth: selected ? 4 : 2.5)
            )
            .shadow(color: Theme.ink.opacity(selected ? 0.8 : 0),
                    radius: 0, x: selected ? 3 : 0, y: selected ? 4 : 0)
            .scaleEffect(selected ? 1.04 : 1)

            Text(preset.name)
                .font(Theme.caption(12))
                .foregroundStyle(selected ? Theme.ink : Theme.ink.opacity(0.6))
                .lineLimit(1)
                .frame(width: 84)
                .minimumScaleFactor(0.7)
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(preset.name))
        .accessibilityHint(Text(preset.tagline))
        .accessibilityAddTraits(selected ? [.isButton, .isSelected] : .isButton)
    }
}
