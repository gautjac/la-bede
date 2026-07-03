import XCTest
@testable import LaBede

/// Covers the style-preset catalog, the diffusion prompt composition, and the
/// Fal.ai response parsing. All pure logic — no network, runs on any Simulator.
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
            XCTAssertFalse(preset.stylePrompt.isEmpty, "\(preset.id) needs a style prompt")
            XCTAssertGreaterThanOrEqual(preset.palette.count, 2,
                                        "\(preset.id) needs ≥2 placeholder tints")
        }
    }

    func testFindFallsBackToDefaultForUnknownID() {
        XCTAssertEqual(StripStyle.find("nope").id, StripStyle.default.id)
        XCTAssertEqual(StripStyle.find("watercolor").id, "watercolor")
    }

    // MARK: - Diffusion prompt composition

    func testComposePromptFusesSceneCharacterAndStyle() {
        let prompt = PanelRenderer.composePrompt(
            scene: "the hero trips on a cable in the studio",
            character: "a round kid in a striped sweater",
            stylePrompt: "clean ligne-claire comic art, bold ink"
        )
        XCTAssertTrue(prompt.contains("the hero trips on a cable in the studio"))
        XCTAssertTrue(prompt.contains("a round kid in a striped sweater"))
        XCTAssertTrue(prompt.contains("clean ligne-claire comic art, bold ink"))
        // Guards that keep the panel clean and free of garbled generated text.
        XCTAssertTrue(prompt.contains("single comic book panel"))
        XCTAssertTrue(prompt.contains("no text"))
    }

    func testComposePromptSkipsEmptyPartsButAlwaysFramesAPanel() {
        let prompt = PanelRenderer.composePrompt(scene: "a quiet room at dawn",
                                                 character: "",
                                                 stylePrompt: "")
        XCTAssertTrue(prompt.contains("a quiet room at dawn"))
        XCTAssertTrue(prompt.contains("single comic book panel"))
        XCTAssertFalse(prompt.contains(".. "), "No empty fragments joined in")
    }

    // MARK: - Fal model

    func testFalModelRawValuesAndLabels() {
        XCTAssertEqual(FalClient.Model.fluxDev.rawValue, "fal-ai/flux/dev")
        XCTAssertEqual(FalClient.Model.fluxSchnell.rawValue, "fal-ai/flux/schnell")
        for model in FalClient.Model.allCases {
            XCTAssertFalse(model.label.isEmpty)
        }
    }

    // MARK: - Fal response parsing

    func testFirstImageURLParsesValidResponse() throws {
        let json = #"{"images":[{"url":"https://fal.example/img/abc.png","width":1024,"height":1024}],"seed":42}"#
        let url = try FalClient.firstImageURL(from: Data(json.utf8))
        XCTAssertEqual(url.absoluteString, "https://fal.example/img/abc.png")
    }

    func testFirstImageURLThrowsWhenNoImages() {
        let json = #"{"images":[]}"#
        XCTAssertThrowsError(try FalClient.firstImageURL(from: Data(json.utf8)))
    }

    func testFirstImageURLThrowsOnGarbage() {
        XCTAssertThrowsError(try FalClient.firstImageURL(from: Data("not json".utf8)))
    }

    func testFalErrorHasFrenchDescriptions() {
        XCTAssertNotNil(FalClient.FalError.noKey.errorDescription)
        XCTAssertNotNil(FalClient.FalError.http(status: 401, body: "bad key").errorDescription)
        XCTAssertTrue(FalClient.FalError.http(status: 401, body: "x").errorDescription!.contains("401"))
    }
}
