import Foundation
import CoreGraphics
import ImagePlayground
import UIKit

/// Renders comic panels with Apple's Image Playground `ImageCreator`
/// (programmatic generation, iOS 26+).
///
/// Two things make a panel actually follow its sentence and look good:
///  1. **Style lives in the `style:` parameter, not the prompt.** The chosen
///     `StripStyle` resolves to a concrete `ImagePlaygroundStyle`; for built-in
///     styles we pass *no* style words in the text at all, so the scene and the
///     recurring character are the only concepts the generator has to depict.
///  2. **Concepts are clean and discrete.** Scene first, character second — no
///     meta-labels like "Art style:" or "A single comic panel" that the
///     generator would otherwise try to draw literally.
///
/// On iOS 26.4+ we use the `options:` overload to disable personalization (so it
/// never grafts the user's face onto the avatar) and, on iOS 27+, request a
/// crisp 1024² panel.
///
/// Apple deprecated `ImageCreator` in iOS 27 in favour of the interactive sheet,
/// but headless batch panel generation still needs it, so we keep using it under
/// availability checks.
@available(iOS 26.0, *)
final class PanelRenderer {

    /// Whether programmatic image generation can run on this device right now.
    static var isAvailable: Bool {
        ImagePlaygroundViewController.isAvailable
    }

    enum RenderError: Error { case unavailable, noImage }

    // MARK: Concept composition (testable, no framework types)

    /// The discrete concept strings fed to the generator, in priority order.
    /// `styleIsFreeform` is decided by the *resolved* style, not the preset, so a
    /// free-form preset that falls back to a built-in style doesn't leak its
    /// style words in as noise.
    static func conceptStrings(scene: String,
                               character: String,
                               freeformPrompt: String,
                               styleIsFreeform: Bool) -> [String] {
        var parts: [String] = []
        if styleIsFreeform {
            let look = freeformPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
            if !look.isEmpty { parts.append(look) }
        }
        let s = scene.trimmingCharacters(in: .whitespacesAndNewlines)
        if !s.isEmpty { parts.append(s) }
        let c = character.trimmingCharacters(in: .whitespacesAndNewlines)
        if !c.isEmpty { parts.append(c) }
        // Always give the generator at least one concept to work with.
        if parts.isEmpty { parts.append(scene) }
        return parts
    }

    private static func concepts(scene: String,
                                 character: String,
                                 freeformPrompt: String,
                                 styleIsFreeform: Bool) -> [ImagePlaygroundConcept] {
        conceptStrings(scene: scene,
                       character: character,
                       freeformPrompt: freeformPrompt,
                       styleIsFreeform: styleIsFreeform)
            .map { .text($0) }
    }

    // MARK: Style resolution

    /// Resolve a preset to a concrete style the device offers, walking the
    /// preset's preference list, then a built-in fallback chain.
    static func resolvedStyle(for preset: StripStyle,
                              available: [ImagePlaygroundStyle]) -> ImagePlaygroundStyle {
        for kind in preset.preferredKinds {
            if let style = playgroundStyle(for: kind), available.contains(style) {
                return style
            }
        }
        if let illustration = playgroundStyle(for: .illustration), available.contains(illustration) {
            return illustration
        }
        return available.first ?? .animation
    }

    /// Map an abstract `StyleKind` to a concrete `ImagePlaygroundStyle`, or nil
    /// when this OS/build doesn't have it.
    static func playgroundStyle(for kind: StyleKind) -> ImagePlaygroundStyle? {
        switch kind {
        case .illustration: return .illustration
        case .animation:    return .animation
        case .sketch:       return .sketch
        case .emoji:        return .emoji
        case .externalProvider: return .externalProvider   // iOS 26.0+
        case .any:
            if #available(iOS 27.0, *) { return .any }
            return nil
        }
    }

    private static func isFreeform(_ style: ImagePlaygroundStyle) -> Bool {
        if style == .externalProvider { return true }
        if #available(iOS 27.0, *), style == .any { return true }
        return false
    }

    // MARK: Availability probe (for the picker)

    /// Which abstract style kinds this device can actually generate right now.
    /// Empty when generation is unavailable (Simulator / non-AI hardware). Used
    /// to hide free-form presets where no provider is connected.
    static func availableStyleKinds() async -> Set<StyleKind> {
        guard isAvailable else { return [] }
        do {
            let creator = try await ImageCreator()
            let offered = creator.availableStyles
            var kinds: Set<StyleKind> = []
            for kind in StyleKind.allCases {
                if let style = playgroundStyle(for: kind), offered.contains(style) {
                    kinds.insert(kind)
                }
            }
            return kinds
        } catch {
            Log.render.error("Style probe failed: \(error.localizedDescription)")
            return []
        }
    }

    // MARK: Render

    /// Render one panel to PNG data using the strip's chosen style. Returns nil
    /// on any failure so the caller can drop in the placeholder for that panel.
    static func renderPNG(scene: String,
                          character: String,
                          style preset: StripStyle) async -> Data? {
        guard isAvailable else { return nil }
        do {
            let creator = try await ImageCreator()
            let chosen = resolvedStyle(for: preset, available: creator.availableStyles)
            let concepts = concepts(scene: scene,
                                    character: character,
                                    freeformPrompt: preset.freeformPrompt,
                                    styleIsFreeform: isFreeform(chosen))

            // Branch rather than share one existential stream — the opaque
            // `some AsyncSequence` return types don't merge under Swift 5 mode.
            if #available(iOS 26.4, *) {
                var options = ImagePlaygroundOptions()
                // Keep the invented avatar — never graft the user's own likeness.
                options.personalization = .disabled
                if #available(iOS 27.0, *) {
                    // Crisp, square panels read far better than the default size.
                    options.sizeSpecification = .closest(to: CGSize(width: 1024, height: 1024))
                }
                for try await created in creator.images(for: concepts, style: chosen,
                                                        options: options, limit: 1) {
                    if let data = pngData(from: created.cgImage) { return data }
                }
            } else {
                for try await created in creator.images(for: concepts, style: chosen, limit: 1) {
                    if let data = pngData(from: created.cgImage) { return data }
                }
            }
            return nil
        } catch {
            Log.render.error("ImageCreator failed: \(error.localizedDescription)")
            return nil
        }
    }

    private static func pngData(from cgImage: CGImage) -> Data? {
        UIImage(cgImage: cgImage).pngData()
    }
}
