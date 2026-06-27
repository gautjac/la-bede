import XCTest
import SwiftUI
import UIKit
@testable import LaBede

/// A render smoke test: build a placeholder strip and prove `StripExporter`
/// produces a real, non-trivial PNG (the comic page renders end-to-end). Runs
/// on any Simulator since it uses the model-free placeholder path.
@available(iOS 26.0, *)
@MainActor
final class RenderSmokeTests: XCTestCase {

    private func sampleStrip() -> Strip {
        let script = StripWriter.localScript(for: "On a marché jusqu'au fleuve, le vent était bête.")
        let panels = script.panels.map { Panel(caption: $0.caption, prompt: $0.scene) }
        return Strip(beat: "On a marché jusqu'au fleuve.",
                     title: script.title,
                     characterDescription: script.character,
                     styleDescription: script.style,
                     renderSource: .placeholder,
                     panels: panels)
    }

    func testExporterProducesPNG() {
        let strip = sampleStrip()
        let data = StripExporter.png(for: strip, width: 600)
        XCTAssertNotNil(data, "The strip should render to a PNG")
        // A real rendered comic page is well over a few KB.
        XCTAssertGreaterThan(data?.count ?? 0, 3000)
        // PNG magic number.
        if let d = data, d.count >= 4 {
            XCTAssertEqual(Array(d.prefix(4)), [0x89, 0x50, 0x4E, 0x47])
        }

        // Sanity: the rendered page should be a reasonable comic-strip aspect
        // (taller than wide), proving the three panels stacked vertically.
        if let img = UIImage(data: data ?? Data()) {
            XCTAssertGreaterThan(img.size.height, img.size.width)
        }
    }

    func testExportURLIsWritten() {
        let strip = sampleStrip()
        let url = StripExporter.exportURL(for: strip)
        XCTAssertNotNil(url)
        if let url { XCTAssertTrue(FileManager.default.fileExists(atPath: url.path)) }
    }
}
