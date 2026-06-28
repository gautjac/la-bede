import XCTest
import ImagePlayground
@testable import LaBede

/// Covers the new style-preset system: the catalog's integrity, the clean
/// concept composition that makes panels follow their sentence, and the
/// device-style resolution + fallback chain. All model-free, so it runs on any
/// Simulator (with or without Apple Intelligence).
@available(iOS 26.0, *)
final class StyleTests: XCTestCase {

    // MARK: - Catalog

    func testCatalogHasUniqueIDsAndDefault() {
        let ids = StripStyle.all.map(\.id)
        XCTAssertEqual(ids.count, Set(ids).count, "Preset ids must be unique")
        XCTAssertTrue(StripStyle.all.contains { $0.id == StripStyle.default.id })
        XCTAssertGreaterThanOrEqual(StripStyle.all.count, 6)
    }

    func testEveryPresetIsWellFormed() {
        for preset in StripStyle.all {
            XCTAssertFalse(preset.name.isEmpty, "\(preset.id) needs a name")
            XCTAssertFalse(preset.symbol.isEmpty, "\(preset.id) needs an SF Symbol")
            XCTAssertFalse(preset.freeformPrompt.isEmpty, "\(preset.id) needs a look prompt")
            XCTAssertFalse(preset.preferredKinds.isEmpty, "\(preset.id) needs style preferences")
            XCTAssertGreaterThanOrEqual(preset.palette.count, 2,
                                        "\(preset.id) needs ≥2 placeholder tints")
        }
    }

    func testBuiltInPresetsDoNotNeedAProvider() {
        XCTAssertFalse(StripStyle.bandeDessinee.needsProvider)
        XCTAssertFalse(StripStyle.dessinAnime.needsProvider)
        XCTAssertFalse(StripStyle.croquis.needsProvider)
    }

    func testFreeformPresetsNeedAProvider() {
        XCTAssertTrue(StripStyle.aquarelle.needsProvider)
        XCTAssertTrue(StripStyle.huile.needsProvider)
        XCTAssertTrue(StripStyle.pixel.needsProvider)
        XCTAssertTrue(StripStyle.noir.needsProvider)
        XCTAssertTrue(StripStyle.estampe.needsProvider)
    }

    // MARK: - Concept composition (the "follow the sentence" fix)

    func testConceptsLeadWithSceneAndCharacterForBuiltInStyle() {
        let concepts = PanelRenderer.conceptStrings(
            scene: "the hero trips on a cable in the studio",
            character: "a round kid in a striped sweater",
            freeformPrompt: "loose watercolour painting",
            styleIsFreeform: false
        )
        // Built-in styles carry the look in the style: parameter, so the look
        // text must NOT appear as a concept — and there are no meta-labels.
        XCTAssertEqual(concepts.first, "the hero trips on a cable in the studio")
        XCTAssertTrue(concepts.contains("a round kid in a striped sweater"))
        XCTAssertFalse(concepts.contains { $0.contains("watercolour") })
        for c in concepts {
            XCTAssertFalse(c.contains("Art style:"))
            XCTAssertFalse(c.contains("Recurring character:"))
            XCTAssertFalse(c.lowercased().contains("comic-strip panel"))
        }
    }

    func testFreeformStyleInjectsLookAsLeadingConcept() {
        let concepts = PanelRenderer.conceptStrings(
            scene: "a cat naps on a warm windowsill",
            character: "a tabby cat",
            freeformPrompt: "loose watercolour painting, soft washes",
            styleIsFreeform: true
        )
        XCTAssertEqual(concepts.first, "loose watercolour painting, soft washes")
        XCTAssertTrue(concepts.contains("a cat naps on a warm windowsill"))
        XCTAssertTrue(concepts.contains("a tabby cat"))
    }

    func testConceptsSkipEmptyCharacterButAlwaysHaveScene() {
        let concepts = PanelRenderer.conceptStrings(
            scene: "a quiet room at dawn",
            character: "   ",
            freeformPrompt: "",
            styleIsFreeform: false
        )
        XCTAssertEqual(concepts, ["a quiet room at dawn"])
    }

    // MARK: - Style resolution + fallback

    func testResolutionPicksFirstAvailablePreferred() {
        // Croquis prefers .sketch; when the device offers it, that's chosen.
        let chosen = PanelRenderer.resolvedStyle(
            for: .croquis, available: [.illustration, .sketch, .animation]
        )
        XCTAssertEqual(chosen, .sketch)
    }

    func testResolutionFallsBackDownThePreferenceChain() {
        // Croquis prefers [.sketch, .illustration, .animation]; with only
        // illustration available it skips sketch and lands on illustration.
        let chosen = PanelRenderer.resolvedStyle(
            for: .croquis, available: [.illustration, .animation]
        )
        XCTAssertEqual(chosen, .illustration)
    }

    func testFreeformPresetFallsBackToBuiltInWhenNoProvider() {
        // Aquarelle prefers the provider styles; with none available it must not
        // crash and should resolve to a real built-in (illustration here).
        let chosen = PanelRenderer.resolvedStyle(
            for: .aquarelle, available: [.illustration, .animation, .sketch]
        )
        XCTAssertEqual(chosen, .illustration)
    }

    func testResolutionWithSingleStyleUsesIt() {
        let chosen = PanelRenderer.resolvedStyle(for: .bandeDessinee, available: [.animation])
        XCTAssertEqual(chosen, .animation)
    }

    func testBuiltInKindsMapToConcreteStyles() {
        XCTAssertEqual(PanelRenderer.playgroundStyle(for: .illustration), .illustration)
        XCTAssertEqual(PanelRenderer.playgroundStyle(for: .animation), .animation)
        XCTAssertEqual(PanelRenderer.playgroundStyle(for: .sketch), .sketch)
    }
}
