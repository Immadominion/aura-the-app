# AURA Mobile App — Design Upgrade Skill
### From: Minimal black/white/blue → Sophisticated financial instrument UI

---

### What you want it to feel like (design5/6/7 + context)
The reference apps show (in order of influence):
1. **Robinhood/Phantom hybrid** — agent icon spheres that feel alive, large SF-style typography
2. **Hyperliquid** (design1) — white sheet modals over a colored background, tick-mark sliders, labeled chart handles
3. **A gold-accent DeFi asset screen** (design3) — full-bleed line chart, "Agent Running" live pill, amber buy/sell pills
4. **Annotation storyboard** (design2) — wallet card scales + dims as chat drawer emerges from beneath

### The gap in one sentence
> You have a flat, correctly-dark app. The references have **depth, hierarchy, and micro-specificity**. The upgrade is not a redesign — it is a *precision pass* on typography scale, surface layering, component corner radii, accent treatment, and motion.

---

## 1. DESIGN PRINCIPLES FOR THIS UPGRADE

These are not aesthetic opinions. They are rules derived directly from analyzing all 7 provided assets.

### 1.1 The Surface Stack (most important rule)
Every reference app uses exactly **three surface levels**. Your app currently uses one or two. You need all three.

```
Level 0 — Base canvas:    #000000  (pure black — the void)
Level 1 — Card surface:   #111111 to #141414  (primary containers, list backgrounds)
Level 2 — Elevated:       #1C1C1C to #1E1E1E  (modals, sheets, active states, inner cards)
Level 3 — Floating:       #252525 to #2A2A2A  (tooltips, dropdowns, pill badges on top of L2)
```

**Why this matters**: In Image 4 (your current app), the wallet screen's action buttons and the coin list rows sit at the same visual depth as the background. There's no perceived lift. The reference apps (design5, design7) achieve the illusion that elements are *sitting on* the screen, not printed onto it.

### 1.2 Typography is the UI
The single biggest visible gap between your app and the references is type handling. Look at design7 (close-up wallet screen):
- Balance number: **~72–80px**, weight **800**, letter-spacing **-0.03em** — it dominates
- "up / down": **~16px**, weight **600**, colored (green/red)
- Percentage pill: **~14px**, weight **700**, inside a filled capsule
- "Agents", "Coins" section headers: **~22–24px**, weight **700**
- Agent name under sphere: **~15px**, weight **600**
- Status ("Active", "Coming Soon"): **~13px**, weight **500**, muted grey

You need **at least 5 type sizes and 4 weight levels** used intentionally. Do not use the system default everywhere.

### 1.3 Radius Logic — Not Uniformly Round
Your current app likely uses one border-radius value everywhere. The references use **semantic radii**:

```
Full pill (50px+): action buttons (Send, Swap, Buy, Sell), status badges, small tags
Large (20–24px):  cards, modals, bottom sheets, agent icon containers
Medium (12–16px): list item rows, input fields, OTP boxes
Small (8px):      inline badges, tight inner elements
Zero (0px):       chart areas, full-bleed content zones
```

**Critical observation from design1 (Hyperliquid)**: The modal sheet itself has ~20px top radius. The two CTA buttons at the bottom are ~28px radius (very pill-like). The "Cancel" button is **not filled** — it uses a muted filled background to create secondary hierarchy. The "Set" button is the primary solid fill. This two-button pattern (muted secondary + solid primary) is more sophisticated than two equal-weight buttons.

### 1.4 The Accent is not Blue — it is Semantic
Your app uses flat blue for everything. The references use:
- **Green** (`#14F195` or `#4CAF50` range): positive PnL, "up", "Active" status, confirmed actions
- **Red** (`#FF3B3B` or `#EF4444` range): negative PnL, "down", stop loss, errors
- **Amber/Gold** (`#F59E0B` or `#D4A843` range): agent running, neutral pending state (see design3's entire UI)
- **Blue** (`#3B82F6`): navigation, links, selected state, your current accent — keep this but narrow its scope
- **Purple** (`#8B5CF6` or your Solana `#9945FF`): ML/AI operations, the Delegate mode

**The rule**: Blue is for navigation and selection. Green/red are for financial state. Amber is for autonomous operation (the agent is doing something). Purple is for AI intelligence. Never use blue to mean "positive" or "active".

### 1.5 Weight Through Omission
Look at design3 (gold asset screen) carefully. The entire bottom half of the screen is essentially empty — just the chart, a timeframe selector row, an agent status pill, a quote, and two buttons. That's it. The emptiness IS the design. Your app likely has too many list rows, too many borders, too much information at equal visual weight.

The rule: **Every screen should have one element at 3x the visual weight of everything else.** On the wallet home, that's the balance number. On an asset screen, that's the chart. Everything else is supporting cast.

---

## 2. COLOR SYSTEM — EXACT SPECIFICATION

### Base Palette
```
--color-bg-base:          #000000   /* Screen background, always */
--color-bg-card:          #111111   /* Primary cards, list backgrounds */
--color-bg-elevated:      #1C1C1C   /* Modals, sheets, inner cards */
--color-bg-floating:      #2A2A2A   /* Tooltips, dropdown items */
--color-bg-input:         #1A1A1A   /* Input fields, OTP boxes */

--color-border-subtle:    #1E1E1E   /* Barely visible dividers */
--color-border-default:   #2E2E2E   /* Visible card borders */
--color-border-strong:    #3E3E3E   /* Active input borders */
```

### Text Palette
```
--color-text-primary:     #FFFFFF   /* Headlines, balance numbers */
--color-text-secondary:   #A1A1AA   /* Labels, subtitles */
--color-text-tertiary:    #52525B   /* Timestamps, footnotes, muted */
--color-text-disabled:    #3F3F46   /* Placeholder text, inactive */
```

### Semantic Colors
```
--color-positive:         #22C55E   /* Up, profit, active, confirmed */
--color-positive-subtle:  #14532D   /* Positive badge background */
--color-positive-glow:    rgba(34, 197, 94, 0.15)  /* Positive area fill on charts */

--color-negative:         #EF4444   /* Down, loss, error, stop loss */
--color-negative-subtle:  #450A0A   /* Negative badge background */
--color-negative-glow:    rgba(239, 68, 68, 0.12)  /* Negative area fill */

--color-agent:            #F59E0B   /* Agent running / autonomous state */
--color-agent-subtle:     #1C1400   /* Agent status background */
--color-agent-glow:       rgba(245, 158, 11, 0.18)

--color-accent:           #3B82F6   /* Navigation, selection, links */
--color-accent-subtle:    #1E3A5F   /* Selected tab, active ring */

--color-ai:               #9945FF   /* ML/AI/Delegate operations */
--color-ai-subtle:        #2D1B69   /* AI feature backgrounds */
--color-ai-glow:          rgba(153, 69, 255, 0.2)
```

### Agent Icon Colors (from design5/7)
These are the 3D-looking sphere icons for agents. Each agent has its own identity color:
```
Execute agent (DeFi):     Blue   — #3B82F6 with inner gradient to #1D4ED8
Automate agent (Stocks):  Green  — #22C55E with inner gradient to #15803D
Delegate agent (Oracle):  Grey   — #52525B with inner gradient to #27272A
```
**How to replicate the sphere look in Flutter/React Native**:  
Use a `Container` with a `BoxDecoration` gradient:
```dart
BoxDecoration(
  shape: BoxShape.circle,
  gradient: RadialGradient(
    center: Alignment(-0.3, -0.4),  // light source top-left
    radius: 0.8,
    colors: [
      Color(0xFF60A5FA),  // lighter highlight
      Color(0xFF2563EB),  // base color
      Color(0xFF1E3A8A),  // dark edge
    ],
    stops: [0.0, 0.5, 1.0],
  ),
  boxShadow: [
    BoxShadow(
      color: Color(0x4D3B82F6),  // 30% opacity glow
      blurRadius: 20,
      spreadRadius: 2,
    ),
  ],
)
```

---

## 3. TYPOGRAPHY SYSTEM — EXACT SPECIFICATION

### Font
**Primary**: SF Pro Display / SF Pro Text (iOS native — use `fontFamily: '.SF Pro Display'` in Flutter or just rely on system font correctly weighted)  
**Mono**: SF Mono or `Courier New` — for wallet addresses, transaction hashes ONLY  
**Do NOT** install a custom font for v1. The sophistication comes from weight and size discipline, not a different typeface.

### Type Scale
```
Display:   72–80px  weight: 800  tracking: -0.03em  — balance numbers, hero stats
H1:        32–36px  weight: 700  tracking: -0.02em  — screen titles (e.g. "Wallets")
H2:        24–28px  weight: 700  tracking: -0.01em  — section headers ("Agents", "Coins")
H3:        20–22px  weight: 600  tracking: 0        — card titles, agent names in modal
Body/L:    17–18px  weight: 400  tracking: 0        — primary body copy, list primary text
Body/M:    15–16px  weight: 400  tracking: 0        — list secondary text, descriptions
Caption:   12–13px  weight: 500  tracking: +0.01em  — labels, timestamps, status text
Micro:     10–11px  weight: 500  tracking: +0.03em  — badges, ticker symbols, units
```

### Critical Typography Rules from the References

**Rule 1: The balance number must breathe.**
In design7, `$5,774.16` is rendered at approximately 72–80px, weight 800. Below it, "up" in green is 16px weight 600, and "1.5%" is inside a filled green capsule at 14px weight 700. This three-layer number treatment (large + direction label + percentage badge) is the signature of the sophisticated fintech look. Your current app (Image 4) shows `$0.0` which appears to be around 40–48px — too small.

**Implementation**:
```dart
// Balance display widget
Column(children: [
  Row(children: [
    Text('\$', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white70)),
    Text('5,774', style: TextStyle(fontSize: 72, fontWeight: FontWeight.w800, letterSpacing: -2.0)),
    Text('.16', style: TextStyle(fontSize: 40, fontWeight: FontWeight.w800, color: Colors.white70)),
  ]),
  SizedBox(height: 8),
  Row(children: [
    Text('up ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: positiveGreen)),
    _PctBadge('+1.5%', color: positiveGreen),
  ]),
])
```

**Rule 2: Section headers are left-aligned, large, and accompanied by a right-aligned chevron-nav.**
From design7: "Agents ›" — the "Agents" text is ~22–24px weight 700, and the "›" chevron on the right indicates the entire section title is tappable to navigate to a full list. This is NOT a small grey label. It commands space.

**Rule 3: Status text uses semantic color + medium weight, never full opacity white.**
"Active" under the blue agent sphere (design7) is in muted grey `#A1A1AA` — NOT green. The green dot badge on the sphere IS the green. The text below is neutral. "Coming Soon" is the same muted grey. This is intentional: the icon communicates state, the text communicates identity.

---

## 4. COMPONENT SPECIFICATIONS

### 4.1 Wallet Home Screen — Full Rebuild Spec

**Current issues**: Wallet address in header is hard to read, balance is undersized, action buttons have equal visual weight to each other and to the content below.

**Target layout** (from design7):
```
┌─────────────────────────────────────────┐
│  [settings ⚙]  evvp...8kuj ∨  [scan □]  │  ← header row, all same grey weight
│                                          │
│              $5,774.16                   │  ← Display size, weight 800
│            up  [1.5%]                   │  ← 16px, green capsule
│                                          │
│  [  Send  ]  [  Swap  ]  [  ···  ]      │  ← Equal-width pills, slightly elevated bg
│                                          │
│  Agents  ›                               │  ← H2 weight 700, tappable
│                                          │
│  [●Agent1]  [●Agent2]  [●Agent3]        │  ← Sphere icons + name + status
│   Probable   Stocks      Oracle          │
│   Active     Coming Soon Coming Soon     │
│                                          │
│  Coins  ›                                │  ← Same H2 treatment
│  ─────────────────────────────────────  │
│  [SOL]  Solana    $4,675.2  [Get]       │  ← Standard list row
└─────────────────────────────────────────┘
```

**Action buttons** (Send / Swap / ···):
- Background: `#1C1C1C` (Level 2 surface — slightly elevated from page bg)
- Border: none, or `0.5px solid #2E2E2E`
- Corner radius: `14px` — NOT full pill, NOT sharp rectangle
- Height: `52px`
- Font: `17px weight 600`
- The "···" button: narrower, `52x52px` circle, same surface treatment
- Equal spacing, same height — but the "···" being circular differentiates it from the text buttons

**Agent section**:
- Horizontal scroll row — 3 visible, scroll to see more
- Each agent: sphere icon (`80x80px`), name below (`15px w600`), status below that (`13px w500 #A1A1AA`)
- Active status indicator: small `10px` filled circle badge, top-right of sphere, color: `--color-positive`
- Inactive: no badge, or grey dot
- Coming Soon: sphere is greyscale/desaturated (use `ColorFilter.mode(Colors.grey, BlendMode.saturation)` in Flutter)

**Coins section list rows**:
- Height: `68px` per row
- Left: token logo `36x36px`, corner radius `10px`
- Middle: token name `17px w600` + symbol `13px w400 muted`
- Right: value `17px w600` + change `13px w500 colored`
- Background: transparent (inherits `#111111` page background)
- Separator: `0.5px solid #1E1E1E` (very subtle — just barely visible)

---

### 4.2 Action Button System

From analyzing design1 (the most detailed button treatment):

**Primary CTA** (e.g. "Confirm", "Buy", "Run Agent"):
```
background: brand accent (green #22C55E OR blue #3B82F6 depending on action type)
color: #000000  ← WHITE IS WRONG. Use black text on colored button for contrast
height: 56px
border-radius: 28px  (full pill)
font-size: 17px
font-weight: 700
letter-spacing: 0 (NOT uppercase — that reads as shouting)
width: stretch to container (minus 20px padding each side)
```

**Secondary CTA** (e.g. "Cancel", "Auto Close"):
```
background: #1C1C1C  ← NOT transparent, NOT outlined, NOT the same color as primary
color: #FFFFFF
height: 56px  ← same height as primary
border-radius: 28px
font-size: 17px
font-weight: 600
```

**Why this is better**: The current design probably either uses outlined buttons (feels cheap on dark) or same-color buttons with opacity differences (unclear hierarchy). The `#1C1C1C` filled secondary button provides clear hierarchy — it reads as "less important" without being ambiguous.

**Two-button row layout rule** (from design1):
```
Row(children: [
  Expanded(child: SecondaryButton('Cancel')),
  SizedBox(width: 12),
  Expanded(child: PrimaryButton('Set')),
])
// Note: primary is ALWAYS on the right
```

**Destructive action** (e.g. "Stop Loss"):
```
background: --color-negative (#EF4444)
text: black
Same height/radius as primary
```

---

### 4.3 Bottom Sheet / Modal — The Most Impactful Single Change

The reference apps (design1, design5) use bottom sheets exclusively for confirmations, settings, and details — NOT full-screen navigation pushes. This is the pattern:

**Sheet structure**:
```
┌──────────────────────────────────────┐
│              ─────                   │  ← drag handle, 4x36px, #3E3E3E, centered
│  Title text (center)    [×]          │  ← 20px w600, X is small grey, top-right
│                                      │
│  [content area]                      │
│                                      │
│  [Primary CTA]                       │  ← full width, pinned to bottom
│  [fine print disclaimer]             │  ← 11px, grey, centered, "AI agents can..."
└──────────────────────────────────────┘
```

**Sheet background**: `#161616` — slightly different from cards inside it so there's contrast
**Corner radius**: `24px` top corners only
**Shadow behind sheet**: No drop shadow. Instead: dim the background to `rgba(0,0,0,0.7)`

**From design5 — Agent Detail Sheet** (the "Stocks Trader" sheet):
```
Layer 1 (sheet bg): #161616
  └── Agent icon: 64px sphere, centered, top of sheet
  └── Title: "Stocks Trader" 22px w700 center
  └── Subtitle: "Autonomous stock trading agent" 15px w400 muted, center
  └── Feature list: icon + text rows, ~44px each
      └── Icon: SF Symbol, 20px, white
      └── Primary text: "Runs for You 24/7" 16px w600
      └── Secondary text: "Keeps watching..." 14px w400 muted, line-height 1.4
  └── CTA: "Get Started" full-width white button (or accent color) 56px
  └── Disclaimer: "AI agents can make mistakes. Markets are risky." 11px muted center
```

**From design5 — Agent Settings Sheet** (the "Trade Settings" nested sheet):
```
Layer 2 (elevated within Layer 1): each setting row is #1C1C1C
  └── Row type 1 — Labeled + Value + Menu:
      "Run For"  [3 Days] [⋮]
      Row bg: #1C1C1C, 52px height, 14px corner radius
      Value: right-aligned, 16px w600, white
      Menu trigger [⋮]: 20px icon, #A1A1AA
  └── Row type 2 — Toggle:
      "Trade Autonomously"  [●●●]
      Toggle: system-style ON = green, OFF = #3E3E3E
  └── Row type 3 — Value + Menu:
      "Risk Level"  [Low] [⋮]
      Same as Row type 1
  └── Row type 4 — Value display:
      "Daily Spend Cap"  $1600/day
      Right value in white, label in muted grey
  └── Visual slider (at bottom of settings, before CTA):
      Thin track (3px height), gradient from green to yellow to red
      No thumb — the fill itself IS the indicator
      Under the track: subtle fill from left to current position
```

---

### 4.4 Slider / Range Input (from design1 — the most detailed reference)

This is the leverage/stop-loss slider. It is unique and sophisticated:

**Visual anatomy**:
```
[Label: "Leverage"]                    [Value badge: 5.6x]
                                              |
  ┊   |    ┊   |    ┊   |    ┊   |    ┊   |  ←  track
  2        3        4        5        6
```

- Track: NOT a filled bar. It is a series of **tick marks** — short vertical lines (~8px tall, ~1px wide) at regular intervals, with taller marks (`~16px`) at integer values. Color: `#3E3E3E` for all unselected, accent color for the selected region ticks.
- Value badge: A filled capsule floating **above** the current position, connected by a vertical line stem. Background: accent color. Text: `14px weight 700`. This is the thumb — it floats above the track, not on it.
- Numbers below: `10px weight 500 muted grey`, one per major division
- The entire thing is **draggable by touching anywhere in the row**, not just the badge

**Flutter implementation approach**:
```dart
// Custom painter for tick-mark slider
// Draw N ticks at equal spacing
// Ticks at integer positions are taller
// Ticks left of thumb are accent-colored
// Ticks right of thumb are #3E3E3E
// Floating badge is a positioned widget above the canvas
```

**Color semantic for sliders**:
- Leverage slider: accent blue ticks for selected
- Stop Loss slider: red ticks for selected (because it represents loss territory)
- Take Profit slider: green ticks for selected (because it represents gain territory)
- Risk Level slider: gradient — green (left/low) → amber (center) → red (right/high)

---

### 4.5 Chart Component (from design3 — the gold asset screen)

**Line chart style**:
- Background: `#000000` (no chart bg color — it bleeds into the screen bg)
- Line: `2px` stroke, color: accent color of the asset/mode
  - For agent gold: `#F59E0B`
  - For positive PnL: `#22C55E`
  - For negative PnL: `#EF4444` (changes dynamically based on current vs. open price)
- Area fill below line: subtle gradient from line color at 15% opacity to 0% at bottom
- No grid lines. No axis labels except Y-axis values floating right.
- Y-axis values: right-aligned, `11px weight 500`, `#52525B` (very muted)
- X-axis values: `11px weight 400`, `#52525B`, only at start/middle/end

**Timeframe selector** (1H / 1D / 1W / 1M / 6M / custom):
- Row of text buttons, no borders, no background
- Inactive: `14px weight 500 #52525B`
- Active: `14px weight 700 #FFFFFF`
- No underline, no capsule background — weight change alone signals selection
- The active item should be slightly larger or use `14px vs 13px` if even more subtle

**Agent status bar** (the pill in design3):
```
┌────────────────────────────────────────┐
│  [●] Agent  •  Running      03:40:03 › │
└────────────────────────────────────────┘
Background: #1C1C1C
Height: 52px
Corner radius: 26px (full pill)
Left: small agent sphere avatar (24px), then "Agent" 15px w600, "• Running" 13px w500 #F59E0B (amber — agent color)
Right: live timer "03:40:03" 13px w500 mono font #A1A1AA, then "›" chevron
The timer increments live — use a Ticker/AnimationController
Entire pill is tappable → navigates to agent detail
```

**The agent status narrative text** (below the pill in design3):
```
│  Watching price action and checking how
│  momentum is shifting on this asset.
```
- Left border: `2px solid #F59E0B` (amber vertical bar — this is the agent speaking)
- Text: `14px weight 400 #A1A1AA`
- This is the agent's current "thought" or last action — not static copy
- Updates when agent takes an action

---

### 4.6 OTP / Invite Code Input (from design4 — your current screen)

**Current**: White background, grey boxes, blue active ring — this is functionally fine but tonally wrong for a dark app.

**Target** (keep the interaction mechanics, change the skin):
```
Background: #000000 (not white)
Headline: "Enter your invite code" — 24px weight 700 white

Each digit box:
  background: #1A1A1A
  border: 1px solid #2E2E2E  (inactive)
  border: 1px solid #3B82F6, width 2px  (active — use your blue)
  border-radius: 14px  (matches medium radius rule — NOT squircle-soft)
  size: 52x60px
  text: 28px weight 700 white
  spacing: 10px between boxes

Error state:
  border: 1px solid #EF4444 on ALL boxes simultaneously
  error text: 14px weight 500 #EF4444, appears below boxes with subtle upward slide animation
  boxes: subtle shake animation (horizontal, 3 oscillations, 300ms total)

Success state:
  border: 1px solid #22C55E on all boxes
  brief pulse glow: box-shadow 0 0 12px rgba(34,197,94,0.4), duration 400ms
  then immediately navigate — don't linger
```

---

### 4.7 The Agent-to-Chat Transition (from design2 — the interaction storyboard)

This is a hero interaction. When user taps an agent sphere on the home screen:

**Step 1 — Tap cue** (first frame of design2):
- The tapped agent sphere receives a quick scale-down: `scale 1.0 → 0.92 → 1.0` in `150ms`
- This is the "tap registered" haptic-visual feedback

**Step 2 — Wallet card recedes** (second frame of design2 — annotated "scaling and opacity reduction of wallet"):
- The wallet header card (balance + action buttons) animates:
  - `scale: 1.0 → 0.94` 
  - `opacity: 1.0 → 0.6`
  - Duration: `300ms`, curve: `easeOut`
- This communicates: "the wallet is still there, but we've shifted focus"

**Step 3 — Chat drawer emerges** (third and fourth frames):
- A chat/message view slides up from below the wallet card
- NOT a new screen push — it's an **in-place expansion** within the same screen
- Background: `#161616` card surface
- Corner radius on top: `20px`
- Agent's chat messages appear with the agent's sphere icon (24px) as avatar
- User chat bubbles: right-aligned, `#3B82F6` fill, white text
- Agent chat bubbles: left-aligned, `#1C1C1C` fill, white text
- Trade execution confirmation appears as a **special message bubble**:
  ```
  [T TSLA logo]  Bought  24.3 TSLA
  ```
  This is a pill/chip inside the message — not plain text. Background `#1C1C1C`, border `1px solid #2E2E2E`, logo on left, "Bought" in muted grey, amount in white.

**Step 4 — Asset detail opens** (fourth frame):
- Tapping the trade execution chip → **slides right** into the asset detail screen
- At this point we see the full asset screen (design3): price, chart, agent status bar, Buy/Sell

**Flutter implementation note**:
```dart
// This is a Hero + SharedAxisTransition or custom AnimatedWidget
// The wallet card recede can be achieved with AnimatedScale + AnimatedOpacity
// The chat drawer emergence is a SlideTransition from bottom
// These should run in parallel, not sequentially
// Total transition: 350ms
```

---

### 4.8 The "Candlestick Chart + Draggable Level Lines" Pattern (from design1)

This is the "Auto Close" sheet — the most technically complex component in all the references.

**What it does**:
- Shows a live candlestick chart in the top 55% of the sheet
- Two horizontal level lines are drawn on the chart: Take Profit (green) and Stop Loss (red)
- Each line has a draggable handle pill on the left edge: `[× Take Profit]` in green or `[× Stop Loss]` in red
- Each line has a price value badge on the right edge: `[$68,541]` in matching color
- As user drags a handle up/down, the line moves, the price updates, the zone fill between lines updates
- The zone between TP and current price is filled with `rgba(34,197,94,0.08)` (green wash)
- The zone between SL and current price is filled with `rgba(239,68,68,0.08)` (red wash)
- Below the chart: two slider rows (same tick-mark pattern) for %-based TP/SL input
- Bottom bar: "Make $111.32 at TP or lose $29.29 at SL" — color each $ amount in its semantic color

**The handle pill**:
```
[× Take Profit]
Background: #22C55E (solid green)
Color: #000000 (black text/icon — not white)
Height: 32px
Padding: 8px 12px
Corner radius: 16px
Font: 13px weight 700
The × dismisses the level. The pill itself is the drag handle.
```

**AURA adaptation**: This exact component maps to your **position management** — showing entry price, current price, stop loss level, and take profit target for an active LP position or trade. Same draggable level metaphor.

---

## 5. MOTION & ANIMATION RULES

### 5.1 Duration and Curve Guide
```
Micro feedback (tap, toggle):  100–150ms  curve: easeOut
UI state change (expand, swap): 250–300ms  curve: easeInOut
Screen transitions:             350–400ms  curve: easeInOut or spring
Background processes (loading): infinite   curve: linear
Data updates (number changes):  600ms      curve: easeOut (count animation)
```

### 5.2 Which Animations to Add First (Priority Order)

**P0 — Add immediately, highest impact**:
1. **Balance number count-up on screen enter**: When wallet screen loads/refreshes, balance ticks up from 0 to current value. Duration: 800ms. easeOut. This one change makes the app feel alive.
2. **Percentage badge color transition**: When PnL changes sign, the badge color crossfades green↔red over 500ms. Don't snap.
3. **Button press scale**: Every tappable surface scales to `0.96` on press, returns on release. `100ms` each way. This is the single most universal quality signal on mobile.
4. **Sheet presentation**: Bottom sheets should slide up from below screen edge, with backdrop dimming simultaneously. Duration: `350ms`, spring curve.

**P1 — Second pass**:
5. **Agent sphere pulse**: Active agents have a very subtle scale pulse: `1.0 → 1.04 → 1.0`, `3s` cycle, `ease-in-out`. Inactive/coming-soon agents do not pulse.
6. **Live timer tick**: The agent runtime timer (03:40:03) — each digit flip uses a vertical scroll micro-animation. New digit slides up from below, old digit exits up. Duration `80ms`. This is the Bloomberg Terminal vibe.
7. **Chart line draw**: When asset screen opens, the line chart draws from left to right over `600ms`. Path animation using `Path.progress` or equivalent.

**P2 — Polish**:
8. Agent-to-chat transition (described in 4.7)
9. Draggable level lines on the chart
10. Staggered list item entrance (each coin row fades in with 30ms stagger from top)

### 5.3 What NOT to Animate
- Do NOT animate navigation pushes with custom transitions — use the system default (right-push). Custom page transitions feel slow and wrong on iOS.
- Do NOT animate modal dismiss with anything other than a downward slide.
- Do NOT use bounce/spring on financial data displays — numbers should feel precise, not playful.
- Do NOT use opacity-only fades for state changes in data — always pair with a micro-transform.
- Do NOT animate colors on the chart area on every price update — only animate when the sign (positive/negative) changes.

---

## 6. ICONOGRAPHY SYSTEM

### 6.1 Icon Style
- **Use SF Symbols exclusively** on iOS builds. Do not mix SF Symbols with custom icons.
- Weight: `medium` for all navigation/action icons, `light` for decorative/secondary
- Size: `24px` for primary actions, `20px` for secondary, `16px` for inline
- Color: inherit from context — white for primary actions, `#A1A1AA` for secondary

### 6.2 Specific Icon Mappings (from the references)
```
Settings/gear:          gear (SF Symbol) — top-left of wallet header
Scan/QR:                qrcode.viewfinder — top-right of wallet header
Wallet address:         shown as truncated text "evvp...8kuj" with ∨ chevron — tappable to see full + copy
Send:                   arrow.up (SF) OR custom "↑ inside circle"
Swap:                   arrow.2.squarepath (SF) — NOT "⇅"
More/Options:           ellipsis (···) — NOT a hamburger, NOT a kebab
Agent section header ›: chevron.right — 16px, weight medium
Close sheet ×:          xmark (SF) — 18px, grey #52525B, top-right of sheet — NOT a button, just an icon tap target
```

### 6.3 The Agent Avatar (most unique component)
The colored sphere icons for agents are NOT standard icons. They are mini brand identities:
- Each is a perfect circle (`80px` on home, `64px` in sheets, `24px` in list rows)
- Each has a unique gradient/illustration that conveys what the agent does
- The green dot active badge sits at `top: 2px, right: 2px` — it's `12px` diameter, `#22C55E`, with a `2px white border` to pop it off the sphere
- **Blur/desaturate inactive agents**: Coming soon agents should use `ImageFilter.blur` or color desaturation — they appear greyed out. This makes the single active agent stand out more.

---

## 7. SCREEN-BY-SCREEN UPGRADE CHECKLIST

### Screen: Wallet Home
- [ ] Balance: increase to 72px weight 800, add letter-spacing -0.03em
- [ ] Up/down direction: change "Up 0.1%" to separate label + filled capsule badge
- [ ] Action buttons: change from solid-fill to `#1C1C1C` surface with 14px radius
- [ ] Add "Agents ›" section header at H2 scale
- [ ] Replace agent text list with horizontal-scroll sphere icon row
- [ ] Add active agent green dot badge
- [ ] Desaturate "Coming Soon" agents
- [ ] Section separators: reduce to 0.5px `#1E1E1E`
- [ ] Add balance count-up animation on load
- [ ] Add button press scale on all tappables

### Screen: Invite Code (Onboarding)
- [ ] Change background from white to `#000000`
- [ ] OTP boxes: change to `#1A1A1A` bg, `14px` radius, `2px blue border on active`
- [ ] Add shake animation on invalid code
- [ ] Add success glow on valid code
- [ ] Error text: slide up from below, red, 14px

### Screen: Agent Detail Sheet
- [ ] Use bottom sheet presentation (not full push)
- [ ] Add drag handle at top of sheet
- [ ] Agent sphere: 64px centered, with glow ring matching agent color
- [ ] Feature rows: icon + primary + secondary text, 44px height each
- [ ] CTA: full-width, 56px, 28px radius
- [ ] Disclaimer: 11px muted centered

### Screen: Agent Settings
- [ ] Each setting row: `#1C1C1C` card, 14px radius, 52px height
- [ ] Replace flat text toggles with proper iOS-style toggle (green ON state)
- [ ] Risk level: replace with gradient slider (green→amber→red)
- [ ] "Run Agent" CTA: full width, 56px pill, accent color

### Screen: Asset / Token Detail
- [ ] Chart: remove chart border/container, let it bleed to edges
- [ ] Line color: dynamic — green if up, red if down from 24h open
- [ ] Add area fill below line (5–15% opacity matching line color)
- [ ] Timeframe selector: weight-only differentiation, no capsule
- [ ] Add agent status pill (if agent is watching this asset)
- [ ] Add agent thought text with left amber border
- [ ] Buy/Sell: two equal-width pill buttons, 56px, 28px radius
  - Buy: `#22C55E` fill, black text
  - Sell: `#EF4444` fill, black text

---

## 8. WHAT NOT TO DO (Explicit Rules)

1. **Do NOT make everything green**. Your product has three modes. Execute = blue. Automate = amber. Delegate = purple. Only PnL and status uses green/red.

2. **Do NOT use white-on-dark outlined buttons**. They look like Bootstrap/web defaults. Use `#1C1C1C` filled secondary buttons.

3. **Do NOT use uniform corner radii**. The design becomes generic. Apply the radius logic from Section 1.3 strictly.

4. **Do NOT use a custom typeface for v1**. The SF Pro weight system is more than sufficient if used at the correct sizes and weights. Adding a custom font that isn't loaded at the right weights reads worse than SF Pro at 800 weight.

5. **Do NOT animate everything**. Only the 4 P0 animations in Section 5.2. More animation ≠ more sophisticated. Precision ≠ busyness.

6. **Do NOT put financial data in equal-weight rows**. The portfolio value, the change, the asset name, the transaction — these are NOT equally important. Use the type scale to enforce hierarchy.

7. **Do NOT use pure `#FFFFFF` for all text on dark backgrounds**. Pure white creates eye strain and makes all text look like it's at the same level. Use `#FFFFFF` only for primary data (numbers, primary labels). Use `#A1A1AA` for secondary, `#52525B` for tertiary.

8. **Do NOT use a bottom tab bar that looks like a standard iOS tab bar**. If you have one, reduce it: max 4 items, no labels (icons only), active state = a 4px dot below icon (not a filled background). Or remove it entirely and use a gesture/nav pattern.

---

## 9. IMPLEMENTATION PRIORITY — ORDERED BY IMPACT/EFFORT RATIO

### Phase 1 — High Impact, Low Effort (Do these first)
These changes touch no logic, only styling:

1. **Balance font size + weight** — 30 minutes. Changes `$0.0` from forgettable to commanding.
2. **OTP screen background** — 5 minutes. Change white to black. Immediate tonal fix.
3. **Button surface color** — 1 hour. Change action buttons from their current fill to `#1C1C1C`.
4. **Section headers** — 30 minutes. "Agents" and "Coins" to H2 scale with ›.
5. **Up/Down badge** — 1 hour. Wrap the percentage in a filled capsule widget.
6. **Button press scale** — 2 hours. Wrap every button in a `GestureDetector` with `AnimatedScale`. This is the single most universally noticed quality signal.

### Phase 2 — High Impact, Medium Effort
7. **Agent sphere icons** — 1 day. Design the 3 gradients, implement with RadialGradient + BoxShadow.
8. **Balance count-up animation** — 3 hours.
9. **Sheet presentation modal** — 1 day. Refactor agent detail from push to bottom sheet.
10. **Semantic color system** — 2 hours. Implement the color tokens and replace all hardcoded colors.

### Phase 3 — Polish (Do these once Phase 1+2 are stable)
11. Chart improvements (line draw animation, area fill)
12. Agent status pill + timer
13. Tick-mark slider for settings
14. Agent-to-chat transition
15. Active agent pulse animation

---

## 10. FLUTTER-SPECIFIC NOTES

Since AURA is built in Flutter (confirmed by your architecture doc — Flutter app, MWA for signing):

### Package Recommendations
```yaml
dependencies:
  flutter_animate: ^4.5.0     # P0: button presses, count-up, shake, slide
  fl_chart: ^0.69.0           # Charts — line, area fill, custom rendering
  modal_bottom_sheet: ^3.0.0  # Cupertino-style bottom sheets
  # DO NOT add: any pre-made UI kit (Flukit, Velvet, etc.) — they won't match your design
```

### Key Flutter Patterns

**Semantic border radius** — define once, use everywhere:
```dart
class AppRadius {
  static const pill = BorderRadius.all(Radius.circular(50));
  static const large = BorderRadius.all(Radius.circular(20));
  static const medium = BorderRadius.all(Radius.circular(14));
  static const small = BorderRadius.all(Radius.circular(8));
  static const zero = BorderRadius.zero;
}
```

**Surface system** — define your color levels as theme extensions:
```dart
class AppSurface extends ThemeExtension<AppSurface> {
  final Color base;     // #000000
  final Color card;     // #111111
  final Color elevated; // #1C1C1C
  final Color floating; // #2A2A2A
  // ... etc
}
```

**Text theme** — replace ALL uses of `TextStyle(fontSize: X)` with named theme styles:
```dart
// In your MaterialApp theme:
textTheme: TextTheme(
  displayLarge: TextStyle(fontSize: 72, fontWeight: FontWeight.w800, letterSpacing: -2.0),
  headlineMedium: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.3),
  bodyLarge: TextStyle(fontSize: 17, fontWeight: FontWeight.w400),
  labelSmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.5),
  // etc.
)
```

**The balance display widget** — implement once, use everywhere:
```dart
class BalanceDisplay extends StatelessWidget {
  final double amount;
  final double changePercent;
  final bool isPositive;
  // Handles Display typography, up/down label, percentage capsule
  // Has built-in count-up animation via flutter_animate
}
```

---

## 11. THE ONE THING

If you only do one thing from this entire document:

**Make the balance number 72px weight 800 with -2.0 letter spacing, and put the percentage change in a filled green/red capsule next to it.**

That single change is responsible for ~40% of the visual sophistication gap between your current screen (Image 4) and the references (design7). Everything else in this document builds on top of that foundation.

---

*Document version: 1.0*  
*Reference sources: design1.mov (Hyperliquid-style trading), design2.jpeg (interaction storyboard), design3.mov (gold agent asset screen), design4.mov (current AURA onboarding), design5.jpeg (agent home + modal mockups), design6.jpeg (interaction annotations), design7.png (wallet home close-up)*  
*Target platform: Flutter (Android primary, iOS secondary) + AURA business context from provided business plan*
