# Aura — Interface Architecture

> This document defines how Aura is structured as an experience,
> not as a collection of screens.

---

## Core Principle

Aura has **three modes**, not four tabs.

The user is always in one of three cognitive states:

| Mode | Name | Mental State |
|------|------|-------------|
| **Execute** | Immediate action | "I want to do this now." |
| **Automate** | Codified intent | "I want this to happen when X occurs." |
| **Delegate** | Surrendered control | "I trust the system. Show me how it's doing." |

These are not features listed in a navigation bar.
They are **states of capital control** that the user transitions between.

---

## Navigation: The Mode Dock

No bottom tab bar. No labels. No badge counts.

A single **floating mode selector** — three glyphs representing levels of control:

```
  ◇        ⟡        ◈
Execute  Automate  Delegate
```

Visual rules:

- The dock is minimal — three icons, nothing else.
- Active mode is indicated by a subtle glow or fill change, not a highlight pill.
- The dock floats above content. Not attached to the bottom edge.
- Swiping horizontally transitions between modes with a crossfade.
- The transition between modes should feel like rotating a dial, not switching tabs.

**Why three, not four:**

The old model had Home + Swap + Automate + Wallet = four tabs.
That's a toolkit layout.

In the new model:

- "Home" doesn't exist as a destination — **each mode's default view IS its status screen.**
- "Wallet" is accessed from a top-right glyph (account/settings), not a mode.
- Settings, wallet identity, forensics — all accessible via a sheet, not a tab.

---

## Each Mode Has Four Layers

Every mode follows the same information hierarchy:

### Layer 1 — Status (Default View)

What the user sees when they enter a mode. One screen. No scrolling required.

**Rules:**

- One dominant metric (large, high-contrast).
- One line of intelligence (contextual subtext).
- One primary action (single button or gesture).
- No cards, no lists, no grids. Pure information.

### Layer 2 — Control (Drill-in)

Accessed by tapping the status panel or pulling up. Shows active state.

**Rules:**

- Lists are acceptable here — but styled as living objects, not data rows.
- Each item shows state (running, paused, pending), not just data.
- Still minimal — 3–5 items maximum before "see all."

### Layer 3 — Configuration (Deliberate Access)

Behind a gear icon, long-press, or explicit "Settings" tap.

**Rules:**

- This is where sliders, toggles, text fields, and pickers live.
- Never shown by default.
- Changes here affect Layer 1 and Layer 2 behavior.

### Layer 4 — Forensics (Deep History)

Accessed from a "History" or "Logs" entry point, never visible on surface.

**Rules:**

- Full trade logs, decision rationale, timestamps, amounts.
- Filterable, searchable, exportable.
- Designed for the user who asks "what exactly happened?"

---

## Mode 1 — Execute

### Layer 1: Status

```
┌─────────────────────────────────┐
│                                 │
│  Available                      │
│  $8,432                         │  ← dominant metric
│  23.5 SOL · 4 tokens            │  ← intelligence line
│                                 │
│                                 │
│                                 │
│         [ Execute ]             │  ← one action
│                                 │
└─────────────────────────────────┘
```

Tapping "Execute" opens the swap flow.

The status screen is not a portfolio breakdown. It answers one question:
**"How much capital is available for execution right now?"**

### Layer 2: Swap Flow

- Search-first token selection (full-screen search, recent tokens surfaced).
- Amount input with number pad (the current pattern is correct).
- Token pair: Pay → Receive.
- Output preview with rate.
- Confirm button.

**Critical:** No route details, no slippage settings, no fee breakdowns on this surface. All of that is behind a "Details" disclosure tap.

### Layer 3: Execution Settings

- Slippage tolerance.
- Gas priority (normal / turbo).
- Route preference (auto / direct).
- MEV protection toggle.

### Layer 4: Transaction History

- Every swap logged: pair, amount, rate, timestamp, tx hash.
- Filterable by token, date range.

---

## Mode 2 — Automate

### Layer 1: Status

```
┌─────────────────────────────────┐
│                                 │
│  3 Active                       │
│  +$127.40                       │  ← dominant metric (net PnL)
│  12 executions today            │  ← intelligence line
│                                 │
│                                 │
│                                 │
│       [ New Strategy ]          │  ← one action
│                                 │
└─────────────────────────────────┘
```

### Layer 2: Strategy List

Strategies are **living objects** — not static cards.

Each strategy shows:

- Name.
- State indicator (pulsing = running, dim = paused, amber = watching).
- Last action and time.
- Net PnL since creation.

Tapping a strategy opens its detail/control view.

### Layer 3: Strategy Builder / Editor

- Trigger configuration (condition picker).
- Action configuration (what happens when triggered).
- Guardrails (limits, cooldowns, stops).
- Templates gallery (pre-built strategies).

### Layer 4: Execution Logs

- Every trigger evaluation: condition met/not met, timestamp.
- Every action taken: trade details, PnL, slippage.
- Strategy performance over time.

---

## Mode 3 — Delegate

### Layer 1: Status

```
┌─────────────────────────────────┐
│                                 │
│  Capital Active                 │
│  5.0 SOL                        │  ← dominant metric
│                                 │
│  Model Confidence: 71%          │  ← intelligence line
│  Net PnL: +0.34 SOL             │
│                                 │
│    [ Deposit ]  [ Withdraw ]    │  ← two actions
│                                 │
└─────────────────────────────────┘
```

This is the most radical screen in the app.

It does NOT show:

- Individual positions (Layer 2).
- Pool names (Layer 2).
- Entry/exit prices (Layer 4).
- Charts (Layer 4).

It shows: **what the system is doing, how confident it is, and how your capital is performing.**

### Layer 2: Active Operations

- Current positions (pool, size, age, current PnL).
- Recent entries/exits with reason.
- Model's current assessment of each position.

### Layer 3: AI Configuration

- Risk dial: Conservative / Balanced / Aggressive.
- Deposit / Withdraw capital.
- Fee preferences.
- Kill switch (pause all operations).

### Layer 4: Decision Log

- Every model prediction: timestamp, confidence, features used.
- Every position: entry reason, exit reason, hold duration, PnL.
- Model performance metrics over time.

---

## Account / Wallet (Not a Mode)

Accessed via a top-right icon (not in the dock). Opens as a sheet or pushes a screen.

Contains:

- Wallet address + copy.
- Connection status.
- Total balance across all modes.
- Performance summary.
- Settings: RPC, notifications, biometric lock, theme.
- Disconnect wallet.

This is not a "tab" — it's infrastructure. The user accesses it occasionally, not as a primary workflow.

---

## Visual Rules

### Dark Mode Primary

The default experience is dark. Light mode exists but is secondary.

Reasoning: Dark mode conveys control, precision, technical authority.
Light mode fintech feels "lifestyle." Aura is infrastructure.

### Typography

- Dominant metrics: 36–48sp, w700, negative letter-spacing.
- Intelligence lines: 14sp, w400, secondary color.
- Actions: 16sp, w600.
- No decorative type. Every word earns its place.

### Color

- Primary accent: a single strong color (teal-green or similar).
- Semantic only: green = positive, red = negative, amber = attention.
- No gradients on surfaces. Gradients only on the AI confidence indicator.
- Background is near-black, not gray.

### Motion

- Mode transitions: crossfade with subtle scale (200–300ms).
- Layer transitions: slide-up for deeper layers, no bouncing.
- State changes (strategy starts/stops): a single pulse, not a celebration.
- No decorative animation. Motion = information.

### Shapes

- Corner radius: 12–16r maximum. Not 24r, not circular cards.
- No pill-shaped containers for content (pills are for chips/badges only).
- Shadows are minimal in dark mode (elevation via brightness, not shadow).

### Iconography

- Line icons (Phosphor Regular) for navigation and actions.
- Filled icons (Phosphor Fill) for active states only.
- No colored icon backgrounds. Icons stand alone.

---

## What This Architecture Kills

1. **The Home screen.** There is no generic "Home." Each mode has its own status view.
2. **The tab bar.** Replaced by the mode dock — three glyphs, not four icons with labels.
3. **Card-heavy layouts.** Layer 1 is pure information, not cards inside cards.
4. **Portfolio as a feature.** Balance is context, not a screen.
5. **Analytics as a surface.** Forensics exist but are buried intentionally.
6. **"Friendly" UX.** No cute copy, no emoji, no lifestyle tone.

---

## Implementation Note

The current codebase uses GoRouter with `StatefulShellRoute.indexedStack` and 4 branches. The new architecture reduces this to:

- 3 mode branches (Execute, Automate, Delegate).
- Account accessible via overlay/sheet from any mode.
- Each branch manages its own layer navigation internally (status → control → config → forensics via nested navigation or sheets).

The mode dock replaces the current floating nav bar.
