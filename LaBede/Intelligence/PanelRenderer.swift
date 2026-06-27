import Foundation
import CoreGraphics
import ImagePlayground
import UIKit

/// Renders comic panels using Apple's Image Playground `ImageCreator`
/// (programmatic generation, iOS 26+). Each panel's prompt is fused with the
/// strip's shared character + style so the three panels read as one strip.
///
/// When Image Playground isn't available (Simulator / non-AI hardware) the
/// caller falls back to `PlaceholderArt`; this type's `isAvailable` reports that.
@available(iOS 26.0, *)
final class PanelRenderer {

    /// Whether programmatic image generation can run on this device right now.
    static var isAvailable: Bool {
        // ImagePlaygroundViewController.isAvailable mirrors the underlying
        // generation availability and is safe to read anywhere.
        ImagePlaygroundViewController.isAvailable
    }

    enum RenderError: Error { case unavailable, noImage }

    /// Build the full prompt for one panel: scene + the shared character and
    /// style anchors, so consistency holds across panels.
    static func composePrompt(scene: String, character: String, style: String) -> String {
        var parts: [String] = []
        let s = scene.trimmingCharacters(in: .whitespacesAndNewlines)
        if !s.isEmpty { parts.append(s) }
        let c = character.trimmingCharacters(in: .whitespacesAndNewlines)
        if !c.isEmpty { parts.append("Recurring character: \(c)") }
        let st = style.trimmingCharacters(in: .whitespacesAndNewlines)
        if !st.isEmpty { parts.append("Art style: \(st)") }
        parts.append("A single comic-strip panel.")
        return parts.joined(separator: ". ")
    }

    /// Render one panel to PNG data. Returns nil on any failure so the caller
    /// can drop in the placeholder for just that panel.
    static func renderPNG(scene: String, character: String, style: String) async -> Data? {
        guard isAvailable else { return nil }
        let prompt = composePrompt(scene: scene, character: character, style: style)
        do {
            let creator = try await ImageCreator()
            // Prefer the illustration style (closest to a drawn comic); fall back
            // to whatever the device offers, then to .any.
            let chosen = creator.availableStyles.first(where: { $0 == .illustration })
                ?? creator.availableStyles.first(where: { $0 == .sketch })
                ?? creator.availableStyles.first
                ?? .animation

            let stream = creator.images(
                for: [.text(prompt)],
                style: chosen,
                limit: 1
            )
            for try await created in stream {
                if let data = pngData(from: created.cgImage) { return data }
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
