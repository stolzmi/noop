# Feature drafts — 2026-11

Status: **draft for discussion**. Nothing here is implemented. Each draft is written to clear the hard
constraints in [AGENTS.md](../../../AGENTS.md) and [SCOPE.md](../../SCOPE.md): on-device only, no
server or account, no telemetry, no medical claims, no new BLE commands. Under the repository's
"one concern per PR" rule, each item would be its own issue first and then its own PR.

Before drafting, the tree was checked for overlap. NOOP already ships a weekly digest
(`WeeklyDigestCard`), a journal and caffeine log, a coach morning brief, a sleep-regularity view
(`RhythmScreen`), quiet hours for notifications, App Intents on Apple, and a trends report renderer on
Apple. None of the drafts below repeats them.

---

## 1. Glyph bridge for Nothing phones (Android, Experimental, default-off)

**What.** On a Nothing phone, show a small amount of NOOP state on the rear Glyph lights:

- during a workout, the live HR zone as a progress segment;
- during an Intervals session, the work/rest phase;
- optionally, once each morning, the recovery band as a short fill animation.

**Why.** It is the hardware counterpart of the Dot refresh, and it gives at-a-glance feedback with the
phone face-down on a bench or nightstand.

**Scope fit.** The data comes from the phone's own database and goes to the phone's own LEDs. Nothing
leaves the device. It is not a strap command, so the BLE safety contract does not apply.

**Shape.** `com.noop.glyph.GlyphBridge` is an interface with a no-op default. A `NothingGlyphBridge`
implementation is selected only when the Glyph service is present. It sits behind an
`ExperimentalFeature` toggle and is off by default. It reads the same live-HR flow that `LiveScreen`
already collects and adds no new BLE subscription.

**Open questions.**
- Licence compatibility of the Glyph Developer Kit with PolyForm Noncommercial 1.0.0. This blocks
  everything else: if the kit cannot be redistributed, the feature does not ship.
- Battery cost of continuous Glyph updates during long sessions. Throttle to zone changes only.

**Parity.** Android-only by nature, with no Apple twin. Call this out in the PR.

---

## 2. Dot widgets and an Android Quick Settings tile

**What.**
- A widget family drawn in the Dot style: a dot-matrix recovery or strain figure with a pip bar
  (`PipBar` already exists in StrandDesign). Small and medium sizes, and an iOS lock-screen
  accessory.
- An Android Quick Settings tile (`TileService`, which the app does not have yet) that shows live HR
  while the strap is connected, opens Live on tap, and starts a workout on long-press.

**Why.** The most common question is "what is my recovery today?", and the answer should not need the
app to be opened. The tile also gives Android the one-swipe entry point that Apple users already get
from App Intents.

**Scope fit.** Widgets read the existing on-device snapshot (`WatchScoreSnapshot`, Android `widget/`).
They make no network calls.

**Shape.** Reuse the existing widget data pipeline. Add a `DotWidgetStyle` rendering only, and
compute no new values. If the widgets are restyled, the numbers must stay byte-identical to the app:
assert this from the shared snapshot rather than recomputing it.

**Verification.** Snapshot tests for the widget view model. On device, check that widget values match
Today after a sync.

---

## 3. Wear coverage calendar ("why is my score missing?")

**What.** A month calendar in which each day is a dot whose fill shows how many hours of strap data
NOOP holds for that day. Tapping a day explains in plain words why a score is missing or provisional,
for example "4 h 10 m of data, below the minimum for a recovery score" or "strap not synced since
21:40".

**Why.** Missing or low-confidence scores are a common support question, and the answer is already in
the database. This is the "a diagnostic may only assert what it can attribute" rule from AGENTS.md
applied to a screen: the calendar may state only gaps it can actually see.

**Scope fit.** It is pure local analytics over stored streams.

**Shape.** Add a pure `WearCoverage.dailyMinutes(streams, tz)` helper in `StrandAnalytics` with a Kotlin
twin. Pin it with an oracle test in the cross-platform style that AGENTS.md describes. The
"missing because" copy reads the same thresholds the scorers use, through one resolver, so the two
cannot disagree.

**Verification.** Swift `swift test` plus a Kotlin test whose expected literals are pasted from the
Swift oracle's stdout.

---

## 4. Snapshot cards (user-initiated image export)

**What.** A Share button on Today, Sleep and a workout detail that renders a clean Dot-style card (date,
the three scores, a small sparkline) to a PNG and hands it to the system share sheet. A
"hide exact values" switch shows only bands, for people who want to share progress but not the numbers.

**Why.** People already screenshot and crop. A purpose-built card is cleaner and leaves out unrelated
on-screen data.

**Scope fit.** This is user-initiated export, which SCOPE.md explicitly allows. The app does no
uploading. It only renders an image and opens the OS share sheet.

**Shape.** On Apple, `ImageRenderer` is already used by `TrendsReportRenderer.swift`, so reuse that
pattern. On Android, render the composable to a `GraphicsLayer` bitmap and share it through a
`FileProvider` URI. Write no EXIF or location data.

---

## 5. Dot readout numerals (the next step of the UI refresh, opt-in)

**What.** An Appearance toggle, "Dot numerals", that draws the big gauge scores (recovery %, strain,
sleep %) in an open-licence dot-matrix face. Doto (SIL OFL 1.1) is the candidate. Labels and body text
stay as they are.

**Why.** This is the strongest single "Nothing-like" cue. It is deliberately left out of the first
refresh because it is the most opinionated change and it adds a bundled font asset.

**Scope fit.** It is purely visual. The font licence must be compatible, and OFL is.

**Shape.** Add `StrandFont.dotDisplay(_:)` and `NoopType.dotDisplay()`, gated by an
`appearance.dotNumerals` preference beside the existing `GaugeNumeralStyle`. The preference is
device-local and not in the `.noopbak` whitelist, like `gaugeNumerals`. Keep tabular figures, or a
monospaced face, so live values do not reflow.

**Verification.** Check that the glyph widths of 0–9 are equal in the chosen face. Take screenshots in
both schemes at the largest Dynamic Type size.

---

## 6. Personal records timeline

**What.** A simple list of the user's own records as they occur: lowest resting HR, highest HRV,
longest sleep, biggest strain day, longest workout. Each record has its date and a link to the day it
happened. It is local only and computed from stored daily aggregates.

**Why.** It gives a positive reason to keep wearing the strap, with no social graph or leaderboard,
both of which SCOPE.md rules out.

**Scope fit.** It is personal-only and offline, and it makes no comparison with other people.

**Shape.** Add a pure helper `PersonalRecords.scan(dailyRows)` with a Kotlin twin and an oracle test.
Show records only once at least 14 days of history exist, so the first week does not produce a "record"
every day.

---

## Not proposed (and why)

- **Cloud sync or a shared leaderboard.** These need a server and accounts, which are out of scope.
- **Illness or arrhythmia alerts beyond the current early-warning.** That would be a medical-device
  claim. SCOPE.md #752 applies.
- **A new strap command for any of the above.** None of these drafts needs one. Each one reads data
  NOOP already stores.
