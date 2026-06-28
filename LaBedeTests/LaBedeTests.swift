import XCTest
@testable import LaBede

/// Tests cover the deterministic, model-free logic so they pass on any CI /
/// Simulator without Apple Intelligence: the local script writer, prompt
/// composition, the seeded RNG's stability, and the Strip model.
@available(iOS 26.0, *)
final class LaBedeTests: XCTestCase {

    // MARK: - Local script writer (the always-available fallback)

    @MainActor
    func testLocalScriptAlwaysHasThreePanels() {
        let script = StripWriter.localScript(for: "J'ai bu un café trop chaud")
        XCTAssertEqual(script.panels.count, 3, "A strip is always a full three-panel page")
        XCTAssertEqual(script.source, .local)
        XCTAssertFalse(script.character.isEmpty)
        XCTAssertFalse(script.style.isEmpty)
        for panel in script.panels {
            XCTAssertFalse(panel.caption.isEmpty)
            XCTAssertFalse(panel.scene.isEmpty)
        }
    }

    @MainActor
    func testLocalScriptReusesUserWords() {
        let beat = "promenade au bord du fleuve"
        let script = StripWriter.localScript(for: beat)
        XCTAssertTrue(script.panels.contains { $0.scene.contains(beat) },
                      "The fallback should weave the user's own words into the scenes")
    }

    @MainActor
    func testLocalScriptHandlesEmptyBeat() {
        let script = StripWriter.localScript(for: "   ")
        XCTAssertEqual(script.panels.count, 3)
        XCTAssertFalse(script.title.isEmpty)
    }

    @MainActor
    func testFallbackTitleCapitalisesAndTruncates() {
        XCTAssertEqual(StripWriter.fallbackTitle("le chat a renversé la plante"),
                       "Le chat a renversé")
        XCTAssertEqual(StripWriter.fallbackTitle(""), "Ma journée")
    }

    // MARK: - Seeded RNG (stable placeholder art)

    func testSeededGeneratorIsDeterministic() {
        var a = SeededGenerator(seed: 42)
        var b = SeededGenerator(seed: 42)
        for _ in 0..<50 { XCTAssertEqual(a.next(), b.next()) }
    }

    func testSeededGeneratorDiffersBySeed() {
        var a = SeededGenerator(seed: 1)
        var b = SeededGenerator(seed: 2)
        XCTAssertNotEqual(a.next(), b.next())
    }

    func testSeededUnitInRange() {
        var g = SeededGenerator(seed: 7)
        for _ in 0..<200 {
            let u = g.unit()
            XCTAssertGreaterThanOrEqual(u, 0)
            XCTAssertLessThan(u, 1)
        }
    }

    // MARK: - Panel & Strip model

    func testPanelSeedIsStableFromPrompt() {
        let p1 = Panel(caption: "a", prompt: "same prompt")
        let p2 = Panel(caption: "b", prompt: "same prompt")
        XCTAssertEqual(p1.seed, p2.seed, "Same prompt → same seed → same placeholder art")
        XCTAssertGreaterThanOrEqual(p1.seed, 0)
    }

    func testStripIsFullyRenderedOnlyWhenAllPanelsHaveImages() {
        let pixel = Data([0x89, 0x50])
        let partial = Strip(
            beat: "x", title: "t", characterDescription: "c", styleDescription: "s",
            renderSource: .playground,
            panels: [Panel(caption: "1", prompt: "a", imagePNG: pixel),
                     Panel(caption: "2", prompt: "b", imagePNG: nil)]
        )
        XCTAssertFalse(partial.isFullyRendered)

        let full = Strip(
            beat: "x", title: "t", characterDescription: "c", styleDescription: "s",
            renderSource: .playground,
            panels: [Panel(caption: "1", prompt: "a", imagePNG: pixel),
                     Panel(caption: "2", prompt: "b", imagePNG: pixel)]
        )
        XCTAssertTrue(full.isFullyRendered)
    }

    func testStripDefaultsToDefaultStyle() {
        // A strip built without an explicit style id should resolve to the default
        // preset (also covers automatic migration of older stored strips).
        let strip = Strip(beat: "x", title: "t", characterDescription: "c",
                          styleDescription: "s", renderSource: .placeholder, panels: [])
        XCTAssertEqual(strip.styleID, StripStyle.default.id)
        XCTAssertEqual(strip.style.id, StripStyle.default.id)
    }

    func testStripStyleRoundTripsAndPaletteIsUsable() {
        let strip = Strip(beat: "x", title: "t", characterDescription: "c",
                          styleDescription: "s", renderSource: .placeholder,
                          panels: [], styleID: StripStyle.aquarelle.id)
        XCTAssertEqual(strip.style.id, "watercolor")
        XCTAssertEqual(strip.style.name, "Aquarelle")
        XCTAssertFalse(strip.style.palette.isEmpty, "Placeholder art needs tints to draw")
    }

    func testUnknownStyleIDFallsBackToDefault() {
        let strip = Strip(beat: "x", title: "t", characterDescription: "c",
                          styleDescription: "s", renderSource: .placeholder,
                          panels: [], styleID: "does-not-exist")
        XCTAssertEqual(strip.style.id, StripStyle.default.id)
    }

    func testRenderSourceRoundTrips() {
        let strip = Strip(beat: "x", title: "t", characterDescription: "c",
                          styleDescription: "s", renderSource: .placeholder, panels: [])
        XCTAssertEqual(strip.source, .placeholder)
        strip.source = .playground
        XCTAssertEqual(strip.renderSource, "playground")
    }

    func testNewestFirstSortsByDate() {
        let old = Strip(beat: "o", title: "o", characterDescription: "", styleDescription: "",
                        renderSource: .placeholder, panels: [],
                        createdAt: Date(timeIntervalSince1970: 1000))
        let new = Strip(beat: "n", title: "n", characterDescription: "", styleDescription: "",
                        renderSource: .placeholder, panels: [],
                        createdAt: Date(timeIntervalSince1970: 2000))
        let sorted = [old, new].newestFirst
        XCTAssertEqual(sorted.first?.title, "n")
    }
}
