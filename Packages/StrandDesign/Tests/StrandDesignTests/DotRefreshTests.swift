import XCTest
@testable import StrandDesign

/// Pins the 2026-11 "Dot" refresh's preset wiring: the Dot preset and the Signal Red accent are reachable
/// from their stored raw values and every selectable preset resolves back to itself. Twin:
/// `DotRefreshTokensTest` (Android), which also pins the monochrome and contrast properties of the token
/// values (a dynamic `Color(light:dark:)` cannot be read back here).
final class DotRefreshTests: XCTestCase {

    func testSignalRedAndDotResolveFromTheirStoredValues() {
        XCTAssertEqual(AccentColor.resolve("signalRed"), .signalRed)
        XCTAssertEqual(ThemePreset.resolve("dot"), .dot)
    }

    func testTheDotRecipe() {
        let r = ThemePreset.dot.recipe
        XCTAssertEqual(r?.accent, .signalRed)
        XCTAssertEqual(r?.chart, .titanium)
        XCTAssertEqual(r?.backdrop, false)
        XCTAssertEqual(r?.cardOpacity, 100)
    }

    func testEverySelectablePresetRoundTripsThroughMatching() {
        for p in ThemePreset.selectable {
            guard let r = p.recipe else { return XCTFail("\(p) has no recipe") }
            XCTAssertEqual(
                ThemePreset.matching(accent: r.accent, chart: r.chart, backdrop: r.backdrop, cardOpacity: r.cardOpacity),
                p
            )
        }
    }
}
