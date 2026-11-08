package com.noop.ui

import androidx.compose.ui.graphics.Color
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import kotlin.math.pow

/**
 * Pins the 2026-11 "Dot" refresh: the chrome neutrals carry no hue, the text ramp stays readable on every
 * surface it is drawn on, and the new Dot preset is reachable and unambiguous. Twin: `DotRefreshTests`
 * (StrandDesign).
 */
class DotRefreshTokensTest {

    private fun lin(v: Float): Double = if (v <= 0.04045f) v / 12.92 else ((v + 0.055) / 1.055).pow(2.4)
    private fun luminance(c: Color): Double = 0.2126 * lin(c.red) + 0.7152 * lin(c.green) + 0.0722 * lin(c.blue)
    private fun contrast(a: Color, b: Color): Double {
        val (hi, lo) = luminance(a).let { la -> luminance(b).let { lb -> if (la > lb) la to lb else lb to la } }
        return (hi + 0.05) / (lo + 0.05)
    }

    private val schemes = listOf("dark" to DarkTokens, "light" to LightTokens)

    @Test
    fun `chrome neutrals are monochrome`() {
        for ((name, t) in schemes) {
            val neutrals = mapOf(
                "surfaceBase" to t.surfaceBase, "surfaceRaised" to t.surfaceRaised,
                "surfaceOverlay" to t.surfaceOverlay, "surfaceInset" to t.surfaceInset,
                "hairline" to t.hairline, "hairlineStrong" to t.hairlineStrong,
                "textPrimary" to t.textPrimary, "textSecondary" to t.textSecondary,
                "textTertiary" to t.textTertiary, "cardFillTop" to t.cardFillTop,
                "cardFillBottom" to t.cardFillBottom,
            )
            for ((token, c) in neutrals) {
                val spread = maxOf(c.red, c.green, c.blue) - minOf(c.red, c.green, c.blue)
                // ≤ 6/255: a neutral may lean a hair warm or cool, never toward a visible hue.
                assertTrue("$name.$token has a hue (channel spread ${spread * 255})", spread <= 6f / 255f + 1e-4f)
            }
        }
    }

    @Test
    fun `text ramp clears WCAG AA on every surface`() {
        for ((name, t) in schemes) {
            for ((surfaceName, surface) in listOf(
                "surfaceBase" to t.surfaceBase, "surfaceRaised" to t.surfaceRaised, "surfaceOverlay" to t.surfaceOverlay,
            )) {
                for ((textName, text) in listOf(
                    "textPrimary" to t.textPrimary, "textSecondary" to t.textSecondary, "textTertiary" to t.textTertiary,
                )) {
                    val c = contrast(text, surface)
                    assertTrue("$name $textName on $surfaceName is ${"%.2f".format(c)}:1", c >= 4.5)
                }
            }
        }
    }

    @Test
    fun `the Dot preset round-trips through matching`() {
        val dot = ThemePreset.DOT
        assertEquals(
            dot,
            ThemePreset.matching(dot.accent!!, dot.chart!!, dot.backdrop, dot.cardOpacity),
        )
        assertEquals(AccentColor.SIGNAL_RED, AccentColor.fromStorage("signalRed"))
        assertEquals(ThemePreset.DOT, ThemePreset.entries.first { it.storageValue == "dot" })
    }

    @Test
    fun `every selectable preset is a distinct recipe`() {
        val recipes = ThemePreset.selectable.map { listOf(it.accent, it.chart, it.backdrop, it.cardOpacity) }
        assertEquals(recipes.size, recipes.toSet().size)
        for (p in ThemePreset.selectable) {
            assertEquals(p, ThemePreset.matching(p.accent!!, p.chart!!, p.backdrop, p.cardOpacity))
        }
    }
}
