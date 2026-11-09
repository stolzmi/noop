import SwiftUI

// MARK: - NOOP visual foundation
//
// These tokens describe the visual treatment used by NOOP's existing views. They deliberately
// contain no navigation, state, or domain semantics: screens keep their current hierarchy and data
// bindings, while cards, gauges, typography, and chrome share one maintainable source of truth.

public enum NoopVisualStyle {
    // "Dot" refresh (2026-11): a monochrome, Nothing-inspired neutral ramp. Surfaces carry no hue at
    // all (the previous ramp leaned blue-grey), so the domain colour worlds are the only colour on
    // screen. Dark is a near-black canvas with charcoal cards; light is an off-white paper with white
    // cards. Text tokens hold equal or better WCAG contrast than the ramp they replace on every surface
    // (dark tertiary 5.0:1 on `surface`, light tertiary 5.1:1). Twin: Android `DarkTokens`/`LightTokens`.
    public static let canvas = Color(light: "#F2F2EF", dark: "#0B0B0C")
    public static let surface = Color(light: "#FFFFFF", dark: "#1A1A1C")
    public static let surfaceTop = Color(light: "#FFFFFF", dark: "#1E1E21")
    public static let surfaceBottom = Color(light: "#FAFAF8", dark: "#1A1A1C")
    public static let inset = Color(light: "#E6E6E2", dark: "#131315")

    public static let border = Color(light: "#DCDCD7", dark: "#2A2A2D")
    public static let borderHighlight = Color(light: "#FFFFFF", dark: "#3A3A3E")
    public static let divider = Color(light: "#E4E4E0", dark: "#29292C")

    public static let primaryText = Color(light: "#111112", dark: "#F5F5F2")
    public static let secondaryText = Color(light: "#4E4E4A", dark: "#B4B4AF")
    public static let tertiaryText = Color(light: "#6E6E69", dark: "#8A8A84")

    public static let mint = Color(light: "#149A78", dark: "#69DDB8")
    public static let mintDeep = Color(light: "#0D765C", dark: "#13A982")
    public static let mintGlow = Color(light: "#38C99E", dark: "#54E6BD")

    /// The "Signal Red" chrome accent (Dot preset): a single saturated red used sparingly against the
    /// monochrome surfaces. 5.9:1 on the light card, 4.4:1 on the dark card. Twin: Android `AccentColor.SIGNAL_RED`.
    public static let signalRed = Color(light: "#C8161D", dark: "#F0393F")
    public static let signalRedGlow = Color(light: "#E0393F", dark: "#FF6B6F")

    public static let cardRadius: CGFloat = 22
    public static let compactRadius: CGFloat = 16
    public static let pillRadius: CGFloat = 999
    public static let pagePadding: CGFloat = 16
    public static let cardPadding: CGFloat = 16
    public static let itemGap: CGFloat = 12
    public static let sectionGap: CGFloat = 26
}

/// Shared card/panel treatment: a flat surface with a single hairline on every platform; macOS adds a
/// soft shadow on light and on elevated panels.
/// `tint` is intentionally faint so metric identity never turns the whole card into a coloured tile.
public struct NoopPanelSurface: View {
    public var tint: Color?
    public var cornerRadius: CGFloat
    public var elevated: Bool
    public var surfaceOpacity: Double
    #if !os(iOS)
    @Environment(\.colorScheme) private var scheme
    #endif

    public init(
        tint: Color? = nil,
        cornerRadius: CGFloat = NoopVisualStyle.cardRadius,
        elevated: Bool = false,
        surfaceOpacity: Double = 1
    ) {
        self.tint = tint
        self.cornerRadius = cornerRadius
        self.elevated = elevated
        self.surfaceOpacity = surfaceOpacity
    }

    public var body: some View {
        let shape = RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
        #if os(iOS)
        // Scrolling stacks contain many panels. Layered translucent gradients and blurred shadows
        // multiply their compositing work, so iOS uses one theme-aware fill and a thin tinted rim.
        // This changes decorative depth only; card geometry and the design-system colors stay the same.
        shape
            .fill(NoopVisualStyle.surface)
            .overlay(shape.strokeBorder(
                tint?.opacity(0.14) ?? NoopVisualStyle.borderHighlight.opacity(elevated ? 0.9 : 0.65),
                lineWidth: 0.8
            ))
            .opacity(surfaceOpacity)
        #else
        // "Dot" refresh: a FLAT fill with one even hairline, like the iOS path above, instead of the
        // top-lit gradient + gradient rim. Depth comes from the fill step between canvas and card; the
        // drop shadow stays only on light (white-on-paper needs it) and on explicitly elevated panels.
        shape
            .fill(NoopVisualStyle.surface)
            .overlay {
                if let tint {
                    shape.fill(
                        LinearGradient(
                            colors: [tint.opacity(0.045), tint.opacity(0.01), .clear],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                }
            }
            .overlay(
                shape.strokeBorder(
                    elevated ? NoopVisualStyle.borderHighlight : NoopVisualStyle.border,
                    lineWidth: 0.8
                )
            )
            .shadow(
                color: scheme == .dark ? .black.opacity(elevated ? 0.30 : 0) : .black.opacity(elevated ? 0.08 : 0.05),
                radius: elevated ? 14 : 6,
                x: 0,
                y: elevated ? 6 : 2
            )
            .opacity(surfaceOpacity)
        #endif
    }
}

/// Shared edge-to-edge chrome for sheet and split-view headers. Unlike a card it has no
/// rounded outline or elevation, but it uses the same top-lit surface ramp and divider token.
public struct NoopChromeSurface: View {
    public init() {}

    public var body: some View {
        LinearGradient(
            colors: [NoopVisualStyle.surfaceTop, NoopVisualStyle.surfaceBottom],
            startPoint: .top,
            endPoint: .bottom
        )
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(NoopVisualStyle.divider)
                .frame(height: 0.5)
        }
    }
}

public extension View {
    func noopPanel(
        tint: Color? = nil,
        cornerRadius: CGFloat = NoopVisualStyle.cardRadius,
        elevated: Bool = false,
        surfaceOpacity: Double = 1
    ) -> some View {
        background {
            NoopPanelSurface(
                tint: tint,
                cornerRadius: cornerRadius,
                elevated: elevated,
                surfaceOpacity: surfaceOpacity
            )
        }
    }
}
