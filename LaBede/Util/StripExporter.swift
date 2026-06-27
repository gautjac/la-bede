import SwiftUI
import UIKit

/// Renders a `StripView` to a shareable PNG using `ImageRenderer`. What the user
/// sees on screen is exactly what gets exported, at a crisp export width.
@MainActor
enum StripExporter {

    /// Render the strip to a high-resolution PNG. Returns nil only if the
    /// renderer can't produce a bitmap.
    static func png(for strip: Strip, width: CGFloat = 900) -> Data? {
        let view = StripView(strip: strip, forExport: true)
            .frame(width: width)
            .environment(\.colorScheme, .light)

        let renderer = ImageRenderer(content: view)
        renderer.scale = 2.0
        renderer.isOpaque = true
        guard let ui = renderer.uiImage else {
            Log.render.error("ImageRenderer produced no image")
            return nil
        }
        return ui.pngData()
    }

    /// Write the PNG to a temp file and return its URL, for ShareLink / export.
    static func exportURL(for strip: Strip) -> URL? {
        guard let data = png(for: strip) else { return nil }
        let safe = strip.title.isEmpty ? "bede" : strip.title
        let name = safe.replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: " ", with: "-")
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("LaBede-\(name).png")
        do {
            try data.write(to: url, options: .atomic)
            return url
        } catch {
            Log.render.error("Failed writing export: \(error.localizedDescription)")
            return nil
        }
    }
}
