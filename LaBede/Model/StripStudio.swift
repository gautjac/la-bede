import Foundation
import SwiftUI
import SwiftData

/// Orchestrates making a strip: writes the script (Foundation Models or local),
/// renders each panel (Image Playground or placeholder), and reports progress so
/// the capture screen can animate panel-by-panel. Observable for SwiftUI.
@available(iOS 26.0, *)
@MainActor
@Observable
final class StripStudio {

    enum Phase: Equatable {
        case idle
        case writing                       // model is drafting the 3-panel script
        case rendering(done: Int, total: Int)  // drawing panels one by one
        case finished
        case failed(String)
    }

    private(set) var phase: Phase = .idle

    /// The work-in-progress strip the capture screen previews live.
    private(set) var draft: Strip?

    private let writer = StripWriter()

    // MARK: Availability (for the graceful state)

    var isIntelligenceAvailable: Bool { writer.isOnDeviceAvailable }
    var isImageGenAvailable: Bool { PanelRenderer.isAvailable }
    var unavailabilityReason: String? { writer.unavailabilityReason }

    /// Whether anything is in flight.
    var isWorking: Bool {
        switch phase {
        case .writing, .rendering: return true
        default: return false
        }
    }

    func reset() {
        phase = .idle
        draft = nil
    }

    /// Make a full strip from a beat. Builds a `Strip` (saved by the caller into
    /// SwiftData) with rendered panels where possible, placeholders otherwise.
    func makeStrip(from beat: String) async -> Strip? {
        let trimmed = beat.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        phase = .writing
        let script = await writer.write(beat: trimmed)

        // Build the strip shell with empty panels first, so the UI can show
        // captions and placeholders immediately while images stream in.
        let initialPanels = script.panels.map {
            Panel(caption: $0.caption, prompt: $0.scene)
        }
        let willRender = PanelRenderer.isAvailable
        let strip = Strip(
            beat: trimmed,
            title: script.title,
            characterDescription: script.character,
            styleDescription: script.style,
            renderSource: willRender ? .playground : .placeholder,
            panels: initialPanels
        )
        draft = strip

        // Render panels one at a time so the UI fills in progressively.
        if willRender {
            let total = strip.panels.count
            phase = .rendering(done: 0, total: total)
            for index in strip.panels.indices {
                let panel = strip.panels[index]
                let data = await PanelRenderer.renderPNG(
                    scene: panel.prompt,
                    character: script.character,
                    style: script.style
                )
                if let data {
                    strip.panels[index].imagePNG = data
                } else {
                    // This panel failed — mark the whole strip placeholder so the
                    // look stays consistent across panels.
                    strip.source = .placeholder
                }
                phase = .rendering(done: index + 1, total: total)
                draft = strip   // nudge observers
            }
            // If not a single panel rendered, fall back fully.
            if !strip.panels.contains(where: { $0.imagePNG != nil }) {
                strip.source = .placeholder
            }
        }

        phase = .finished
        return strip
    }
}
