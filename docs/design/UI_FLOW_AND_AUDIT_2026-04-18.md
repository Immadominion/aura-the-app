# Aura — UI Flow & Audit (2026-04-18, rev. 2)

> One document. Every screen the app currently has, what it says, what's wrong with it, what's missing, and the target flow we're going to build toward.
> Written from the seat of: **senior product designer + app architect** who has read the business plan, the Meteora docs, the existing interface architecture, and the mobile design skill — and revised after the founder pushed back on terminology, tone, and IA assumptions.
> No code changes here. This is the map. Implementation is gated behind founder sign-off.

**Rev 2 changes (founder feedback applied 2026-04-18):**

- Kill the legacy [swap_screen.dart](aura/lib/features/swap/presentation/swap_screen.dart) and the `lib/features/swap/` folder entirely. It is unrouted, mislabeled, and not coming back.
- Drop the `Execute · Automate · Delegate` rebrand. The app uses **Home · Chat · Automate**. "Delegate" is long English for nothing; "Home" is what humans call it.
- Drop the "three ways to deploy capital" onboarding card. Even the founder couldn't tell those three modes apart from the names alone — that's the proof the framing was wrong.
- Reframe **Chat** as the *central surface* of the app: it can do everything else in the app. Not a peer mode, not an ambient layer — the brain. Other screens become shortcuts/visualizations of what Chat can already do via voice/text.
- Rewrite onboarding copy + Connect Wallet copy with a web2-leaning, founder-approved voice. No "never holds your keys" (we may swap wallet infra). No insider-only Meteora terminology in the headline.
- **Keep Home as-is** (with the 2-each shortcuts to Bots and Positions). The whole point of Home is to be a launchpad for the deeper screens.
- **Keep Automate as-is** structurally. Don't drop the stat chips; don't move the Fleet banner.
- New §9: **Hackathon-aligned integrations** — [Phantom](phantom/) Flutter SDK (we built our own — story for the Phantom track), [LP Agent](bounty.txt) endpoints + Zap-in/Zap-out (the bounty), and Colosseum Copilot positioning notes.

---

## 0. Reading order

1. §1 — What exists today (route map + per-screen audit)
2. §2 — What the app is *supposed* to be (business + Meteora reality check)
3. §3 — The redundancy + missing-surface audit
4. §4 — The information architecture (3 surfaces + Chat as the brain)
5. §5 — Screen-by-screen target spec (delta from current)
6. §6 — New screens we are adding
7. §7 — Branding & native-feel rules (so the design IS the brand)
8. §8 — Build order — what we'll do first when we start the visual pass
9. §9 — Hackathon-aligned integrations (Phantom, LP Agent, Colosseum Copilot)

---

## 1. The app today — every route, every page

Source of truth: [aura/lib/core/router/app_router.dart](aura/lib/core/router/app_router.dart).

### 1.1 Route table (as wired right now)

| Route | Screen | Layer | File |
|---|---|---|---|
| `/splash` | Splash | pre-app | [splash_screen.dart](aura/lib/features/splash/presentation/splash_screen.dart) |
| `/onboarding` | Onboarding (3 pages) | pre-auth | [onboarding_screen.dart](aura/lib/features/onboarding/presentation/onboarding_screen.dart) |
| `/connect-wallet` | Connect Wallet (SIWS via MWA) | pre-auth | [connect_wallet_screen.dart](aura/lib/features/auth/presentation/connect_wallet_screen.dart) |
| `/setup` | Setup wizard (3 steps) | post-auth, one-time | [setup_screen.dart](aura/lib/features/setup/presentation/setup_screen.dart) |
| `/` (shell-0) | Home — "deployed capital + bots + positions" | Mode 1 | [home_screen.dart](aura/lib/features/home/presentation/home_screen.dart) |
| `/intelligence` (shell-1) | Aura Chat | Mode 2 | [aura_chat_screen.dart](aura/lib/features/chat/presentation/aura_chat_screen.dart) |
| `/control` (shell-2) | Automate — bot list + PnL | Mode 3 | [automate_screen.dart](aura/lib/features/automate/presentation/automate_screen.dart) |
| `/profile` | Profile / Identity / Settings | overlay | [profile_screen.dart](aura/lib/features/wallet/presentation/profile_screen.dart) |
| `/fleet` | Fleet leaderboard | overlay | [fleet_screen.dart](aura/lib/features/fleet/presentation/fleet_screen.dart) |
| `/position/:id` | Position detail | overlay | [position_detail_screen.dart](aura/lib/features/home/presentation/position_detail_screen.dart) |
| `/history` | Trade history | overlay | [position_history_screen.dart](aura/lib/features/home/presentation/position_history_screen.dart) |
| `/strategy/:botId` | Strategy / bot detail | overlay | [strategy_detail_screen.dart](aura/lib/features/automate/presentation/strategy_detail_screen.dart) |
| `/create-strategy` | Create new strategy (3 steps) | overlay | [create_strategy_screen.dart](aura/lib/features/automate/presentation/create_strategy_screen.dart) |
| (legacy) | "Intelligence" old screen — XGBoost stats | dead branch | [swap_screen.dart](aura/lib/features/swap/presentation/swap_screen.dart) |

There's also `swap/` as a *folder* but it's not actually wired into the router any more — the chat screen took over `/intelligence`. The old "Intelligence" model-stats view lives on as an orphan.

### 1.2 Per-screen audit

For each screen: **what it says · what's good · what's wrong · what's missing**.

#### Splash — `/splash`

- **Says**: AURA wordmark drops, logo expands, tagline "Autonomous LP Intelligence" fades in. ~3.8 s mandatory hold.
- **Good**: On-brand. The tagline finally tells you what this is.
- **Wrong**: 3.8 s is too long when the user re-opens the app 20×/day. The animation is great for a first impression, awful for a daily driver.
- **Fix**: Full animation only on cold start + first-ever launch. On warm/resumed launches, skip directly to the route resolution after ~600 ms.

#### Onboarding — `/onboarding` (3 cards)

- **Says**:
  1. "Your capital, always working" — Aura deploys SOL into Meteora LP, ML finds high-yield ops.
  2. "Automate your trading strategy" — define rules, deploy 24/7, no code.
  3. "Controlled power, in your hands." — strict risk and spend limits.
- **Good**: Three clean cards, dark navy hero panel, white text panel, swipe + tap nav. Branding is consistent with splash.
- **Wrong**:
  - The copy is undifferentiated from every other DeFi app. Card 2 (Automate) and Card 3 (Controlled power) say almost the same thing — "you control it, set rules, set limits".
  - We mention **Meteora LP** in Card 1 but never explain *why* this matters to a non-degen user.
  - There's no card that explains why Aura is different from every other "AI DeFi" app — i.e. that we've actually trained a model on real on-chain data.
- **Fix (rev 2 — founder voice, web2-leaning, no insider jargon in headlines)**: Three cards that earn their slot. **Headlines stay readable; the technical proof lives in the sub-copy**, so a curious newcomer can land on this and not bounce.
  1. **"Put your capital to work."**
     Sub: *Aura deposits your SOL into top liquidity pools on Solana and earns trading fees for you — automatically, 24/7.*
     Visual: simple bin/curve illustration that *suggests* concentrated liquidity without naming it. The word "Meteora" appears small, in the sub-copy, as a credit ("Powered by Meteora").
  2. **"Backed by our AI research product."**
     Sub: *We've studied tens of millions of real Solana trades to figure out which pools are worth entering — and when to leave.*
     Visual: a confident stat block (`v3 model · trained on 50M+ events`). Don't show "0.94 AUC" on the headline screen — it scares non-quants. Save AUC/precision for the in-app model card (see Chat header pill).
  3. **"You're in control. Always."**
     Sub: *Set your spending limit, your risk level, and your stop-loss. Aura plays inside your rules — and you can pause everything with one tap.*
     Visual: a tactile slider + a kill-switch button. Reassures the security-minded user.
  - **Killed**: the original "three ways to deploy capital" preview card. Even the founder couldn't parse Execute/Automate/Delegate from labels alone — proof the framing was wrong. The dock will be discoverable in-app; we don't need to teach it on day 0.
  - **Tone rule**: every headline must pass the *"could my non-crypto cousin read this and not feel stupid"* test. Sub-copy can be a notch more technical because it's read after the headline already earned attention.

#### Connect Wallet — `/connect-wallet`

- **Says**: "Connect your wallet" + "Make your own rules, or use our Aura Agent. LP while you sleep, it's never been easier." + Connect Wallet button.
- **Good**: Clean dark layout, hero image, Rive-ready slot, friendly subtitle.
- **Wrong**:
  - Image is a stock onboarding render, not on-brand.
  - "LP while you sleep" is too casual for an institutional-instrument tone.
  - Sub-copy doesn't actually answer the question the user is asking at this exact moment: *"why am I being asked to connect a wallet?"*
- **Fix (rev 2 — founder voice, infra-agnostic, no security promises we'd have to walk back)**:
  - Headline: **"Connect your Solana wallet."** Plain. No drama.
  - Sub-copy: *"This is how Aura signs trades and tracks your portfolio. Your wallet stays yours."* — explains *purpose* (sign + track) without making any architectural promise ("never holds your keys") that locks us into one wallet model. If we later support a custodial sub-wallet for sub-accounts, this copy still holds.
  - Below the CTA: a single muted line — *"Works with Phantom, Solflare, and other Solana wallets."* Tells the user this is standard, not exotic.
  - Drop the stock onboarding image; replace with the Aura mark in the same surface treatment as splash. Continuity > stock art.
- **Why we walked back "never holds your keys"**: We may add a Phantom-embedded sub-wallet (see §9.1) for per-bot isolation. That's technically Aura-managed key material, even if the UX is non-custodial-feeling. Promising "never" in headline copy would force a doc rewrite the day we ship that. *"Your wallet stays yours"* is true under both architectures.

#### Setup wizard — `/setup` (3 steps)

- Step 0: Path picker — `Aura AI` vs `Custom Strategy` + execution mode radio (Simulation / Live).
- Step 1: Configure — either GuardrailsStep (sliders for position size, daily limit, profit target, stop loss) **or** CustomStrategyStep (full slider grid: entry score, min/max liquidity, min volume, position size, max concurrent, bin range, profit target, stop loss, max hold, daily loss limit, cooldown).
- Step 2: Review + (live mode) deposit + Activate.
- **Good**: Honest two-path split. Sliders ([custom_strategy_step.dart](aura/lib/features/setup/presentation/widgets/custom_strategy_step.dart)) give actual control over the 12 backend parameters the engine consumes.
- **Wrong**:
  - The wizard collects strategy params **before the user even sees a bot exist**. They're configuring something abstract.
  - "Simulation vs Live" radio is buried at the bottom of step 0 — this is the single biggest cognitive decision and we make it look like a footnote.
  - Custom step has 12 sliders behind 4 collapsibles. Brutal for a first-run user.
  - No bin/curve preview anywhere — they pick "bin range = 20" with zero idea what that *looks like* on a DLMM pool.
- **Fix** (covered in §5.4): same flow, but step 1 becomes a *visual* configurator (bin distribution preview, curve selector, fee tier chip), and the simulation/live decision is promoted to a full-screen dual card.

#### Home — `/` (the launchpad)

- **Says**: Top dark hero — `HOME` label, total deployed SOL, P&L, "N active". Light panel below — Positions/Win-Rate stat boxes, "YOUR BOTS" (top 2 rows + see all), Active Positions section, Trade History link.
- **Good**: The dark-hero / light-panel split is genuinely beautiful. PositionsSection actually surfaces live LP positions which the old design hid. **The 2-each shortcut pattern is correct** — Home is meant to be a launchpad to the deeper screens (Bots → Automate, Positions → Position Detail, Trade History → History). That's *why* it's called Home.
- **Wrong (rev 2 — founder kept Home naming + the launchpad pattern, so most of the original critique is withdrawn)**:
  - Hero says "0.0 SOL" + "0.00 SOL earned · 0 active" by default. New users get a screen full of zeros. That's the entire first impression.
  - The empty/zero state has no narrative — we should be teaching, not showing zeros.
- **Fix (rev 2)**:
  - **Keep the name "Home".** Founder is right — it's what humans call it, and the architecture-doc rule against generic "Home" was over-prescriptive given Aura's actual UX (Home really is a launchpad here, not a duplicate status screen).
  - **Keep the 2-each shortcuts** to Bots and Positions. They are the point of the screen.
  - **Keep the stat boxes** (Positions / Win Rate) — they are summary glances appropriate for a launchpad.
  - **Fix the zero state**: when no bots and no positions, replace the lower panel with a 2-card vertical stack: **[ Talk to Aura ]** (opens Chat with a starter prompt: *"How should I start?"*) and **[ Create a strategy ]** (opens `/create-strategy`). Both warmer than "Deploy your first agent".
  - **Fix the H2 collision**: "YOUR BOTS" and "Active Positions" headers both look identical right now. Demote "YOUR BOTS" to a section label (12 sp, letter-spaced, tertiary color) and let "Active Positions" hold the H2 weight. One H2 per panel scroll.

#### Chat — `/intelligence` (the brain of the app, not a peer mode)

- **Says**: Voice-first chat with Aura. Cycling suggestions when idle. Chat history visible. Strategy params card pops up over a blurred background when Aura proposes a strategy.
- **Good**: Voice-first input is a real differentiator. The strategy-card-with-blur reveal is the most polished single interaction in the app. **Founder intent (corrected from rev 1)**: Chat is supposed to be the *central surface* — *anything* you can do elsewhere in the app, you can do via Chat. It's not a sidekick mode; it's the brain. The other screens are visualizations / shortcuts of what Chat could already do conversationally.
- **Wrong (rev 2)**:
  - Chat doesn't yet expose its own scope to the user. The cycling suggestions only hint at strategy creation. A first-time user has no idea they can also say *"show me my positions"*, *"close bot 3"*, *"what's the best pool right now"*, *"deposit 5 SOL into Aura AI"*.
  - When Aura proposes params, it lifts the user *out of the conversation* into Create-Strategy. The conversation is then orphaned — there's no link back saying "this strategy came from chat #142".
  - The "orphan model-stats view" mentioned in rev 1 is a non-issue and is being deleted (see §8 step 0). The user is right: ROC AUC and XGBoost version numbers are *engineer telemetry*, not user-facing content. They don't belong in Chat or anywhere in the app.
- **Fix (rev 2)**:
  - **Expand the cycling suggestions** into 4 categories (rotate through them on idle): *Strategy* ("Create a strategy for SOL/USDC"), *Portfolio* ("How are my bots doing?"), *Action* ("Pause everything"), *Discover* ("What pools are trending?"). Teaches the scope without a tutorial.
  - **Add a thin status pill** at the top of the chat — but it shows *Aura's current state* in plain English (e.g. "Watching 12 pools · 2 bots running"), not engineer telemetry. Tap → opens a sheet that lists what Aura is currently doing, in human terms.
  - **Round-trip Chat ↔ Create-Strategy**: when Aura proposes params, the resulting bot is tagged with the source `chatThreadId`. On the bot detail screen, a small "Started from Chat ›" link returns to that thread.
  - **Long-term ambition (out of v1 scope, but architecture must allow it)**: Chat becomes the unified action layer. Every action elsewhere in the app (deposit, withdraw, pause bot, swap, view position) routes through the same intent system that Chat consumes. The visual screens are surfaces over the same intent grammar.

#### Automate — `/control`

- **Says**: Top — `Automate` label, big PnL number, running/trades line, three stat chips (Trades / Win Rate / Bots), Fleet Leaderboard banner CTA, BOTS section with strategy cards. Long-press a bot to rename. FAB → `/create-strategy`.
- **Good**: Pinned-header + scrolling-cards is the right pattern. PnL is dominant. The Fleet banner is a smart cross-link. **Founder verdict (rev 2): keep this screen as it is structurally.** The repetition between Home and Automate is intentional — Home is a launchpad with summaries, Automate is the operator console with the same key numbers in fuller context. That's how good operator UIs work.
- **Wrong (rev 2 — most of the original critique is withdrawn)**:
  - There's no concept of **strategy templates**. Every bot is built from scratch from sliders. This is real friction for new users.
  - First-time empty state currently shows just an empty BOTS list under the header. No teaching.
- **Fix (rev 2)**:
  - **Keep the stat chips**. They are the operator's at-a-glance.
  - **Keep the Fleet banner where it is**. It's a real feature; demoting it would hide it.
  - **Add Strategy Templates as a *secondary* surface**: when the user taps `+` to create, the first step of `/create-strategy` gains a horizontal scroll of 3–5 preset cards ("Conservative DLMM", "Aggressive Memecoin", "Stable Pair Grinder", etc.) above the existing Aura-AI / Custom path picker. Picking a template auto-fills the sliders. Doesn't replace the existing flow — accelerates it.
  - **Empty state**: when no bots, replace the empty BOTS list with a single illustrated card — *"No bots yet. Want Aura to set one up for you?"* + **[ Talk to Aura ]** + **[ Build it yourself ]**.

#### Strategy / Bot Detail — `/strategy/:botId`

- **Says**: Bot identity (name, mode, status), big PnL, engine stats, parameters, live positions, controls (Start / Stop / Stop-sheet / Edit Config / Withdraw / Convert-to-Live / Delete).
- **Good**: Full operator view, lots of real controls, an actual stop sheet with two semantically-different stop options ("Stop scanning" vs "Close all & stop"). That sheet is one of the best-designed pieces of UI in the codebase.
- **Wrong**:
  - No **chart**. A bot has lifetime PnL, win rate, daily loss → these all want to be a sparkline at minimum. We currently show them as text only.
  - "Parameters" is a flat list of 12 rows. There's no preview of what those parameters *mean* in market-shape terms (no bin distribution preview, no curve type, no fee tier).
  - "Live positions" are listed but the position rows are flat — no per-position bin map or current price marker.
- **Fix**: Add a 7-day PnL sparkline under the headline number. Add a "Strategy Shape" mini-card showing bin range visually. Position rows get a tiny inline bin indicator (active bin highlighted).

#### Position Detail — `/position/:positionId`

- **Says**: Status (Active/Closed) + LIVE badge, pool name, P&L (large), Deposited / Fees / Hold-time chips, DETAILS section (entry price, current price, bin step, entry bin id, entry score, exit reason), MODEL ASSESSMENT (ML probability bar + descriptive text), Close Position button.
- **Good**: The MODEL ASSESSMENT block is exactly the kind of "why" content the business plan demands.
- **Wrong**:
  - No price chart. A position is a trade — every other LP/trading tool on Solana shows entry, current, and bin range as a chart. We show them as numbers.
  - No bin distribution view (this is THE thing that distinguishes DLMM from DAMM — concentrated liquidity in bins). We collected `binStep` and `entryActiveBinId` and threw them on screen as text. That's a design failure.
  - No fees-over-time series.
  - No "what is this position currently doing right now" status (in range / out of range / one-sided). Critical info for an LP — silent here.
- **Fix**: This is the screen that needs the most visual investment — see §5.6.

#### Position History — `/history`

- **Says**: TRADE HISTORY label, total PnL, total/wins/losses, per-position rows.
- **Good**: Clean. Win/loss color bar on the left of each row works.
- **Wrong**: Loses information that the bot detail page has (which bot did the trade? which strategy version?). No filters. No sort.
- **Fix**: Add a simple filter chip row (All / Wins / Losses / By Bot) and a per-row "from {bot.name}" sublabel.

#### Profile — `/profile`

- **Says**: Identity card (avatar, domain or shortAddr), portfolio summary, Live + Simulation balance split, Deposit/Withdraw buttons, LIVE WALLETS list, settings overlay (gear button rotates to ×).
- **Good**: The DiceBear avatar + AllDomains lookup is delightful. Deposit/Withdraw split is correct.
- **Wrong** (the user explicitly called this out):
  - Settings overlay is a kitchen sink — RPC selector, notification toggles, theme switch, biometric lock, support links, version, etc. all in one slab. Most of it is never touched after first launch.
  - Identity card is *huge* (24 px padding, 32 px radius, shadow) on top of a portfolio summary that is *also* a card with shadows. Two competing focal points.
  - Live + Simulation balance split is legitimately useful but presented as small grey rows when this is the second-most-important number in the app (after the PnL on the active mode).
  - "LIVE WALLETS" lists each per-bot wallet inline with a copy icon — but the user already saw their bots on Automate. This is redundant and exists only because the per-bot wallet UX leaked into Identity.
- **Fix**:
  - Identity becomes minimal: small avatar + name + address-pill. That's it.
  - Portfolio split becomes the dominant block: **Live SOL** big, **Simulation SOL** secondary, both with a sparkline.
  - Settings overlay collapses to **3 entries**: *Risk preferences · Notifications · Advanced*. Everything else lives behind "Advanced".
  - Per-bot wallets disappear from Profile (they live on the bot detail screen where they belong).

#### Fleet — `/fleet`

- **Says**: Platform stats hero (total PnL, total bots, total trades), sort chips (PnL / Win Rate / Trades), leaderboard list.
- **Good**: A real social hook that doesn't compromise the institutional tone.
- **Wrong**: Each leaderboard row is one-dimensional (rank + name + one number). No visualization of *how* the top bots win — strategy mode? AI vs custom? avg position size?
- **Fix**: Each row gets a small "strategy mode dot" (green = Aura AI, blue = Custom, purple = Hybrid) — instantly readable competitive intelligence.

#### Create Strategy — `/create-strategy`

- Same 3-step flow as Setup (Path → Configure → Review). Only difference: doesn't write `setupCompleted`.
- **Wrong**: 100% duplicate logic with Setup. Every change has to be made in both. The `path_step.dart`, `guardrails_step.dart`, `custom_strategy_step.dart`, `review_fund_step.dart` widgets are shared, but the orchestrator state is duplicated.
- **Fix**: Single "StrategyComposerScreen" with a `mode: StrategyComposerMode { firstSetup, addNew }`. Setup screen becomes a thin wrapper that pre-fills onboarding context.

---

## 2. Reality check — Aura vs the world it lives in

### 2.1 The business says

From [business-scope.md](aura/docs/business/business-scope.md):

- Three modes (per business doc): **Execute · Automate · Delegate**. *Founder rev 2 retires this rebrand — the actual dock is **Home · Chat · Automate**, see §4.*
- Vibe: **controlled power · institutional intelligence in your pocket**.
- Moat: 50M+ decoded historical events + a trained XGBoost (0.94 AUC). *Telemetry only — never headline copy.*
- Revenue: 10% performance fee on Aura-AI bots, 0.15% Jupiter swap fee, $9.99/mo Pro.

### 2.2 The interface-architecture says

From [interface-architecture.md](aura/docs/design/interface-architecture.md):

- **3 modes, 4 layers each**: Status → Control → Configuration → Forensics.
- Each mode's default view IS its status screen. There's no global "Home".
- Mode dock = three glyphs, no labels, no badge counts.
- Wallet/account is *not* a mode — it lives behind a top-right glyph.

### 2.3 Meteora reality

From [MeteoraAg/docs/overview/home.mdx](MeteoraAg/docs/overview/home.mdx) — Meteora has **8 ways to earn**, not 1:

| Surface | What you do | Aura support today |
|---|---|---|
| **DLMM** | LP into bin-based concentrated liquidity | ✅ Core supported |
| **DAMM v2** | LP with optional concentrated liquidity + position NFTs | ❌ Invisible in app |
| **DAMM v1** | Constant-product LP + lending yield overlay | ❌ Invisible |
| **Dynamic Bonding Curve (DBC)** | Launch / earn on virtual bonding curves | ❌ Invisible |
| **Alpha Vault** | Anti-bot pre-launch deposit & buy | ❌ Invisible |
| **Stake2Earn** | Stake → fee-share trading fees | ❌ Invisible |
| **Dynamic Vault** | Auto-route idle deposits to lending | ❌ Invisible |
| **Dynamic Fee Sharing** | Programmatic fee splits | ❌ Invisible |

We are a "smart LP app" that has hidden 7 of the 8 LP surfaces from the user. We aren't smart — we're narrow.

### 2.4 The smart-LP gap

The app calls itself **smart LP** but the configuration UI is an array of context-free numeric sliders. There is no:

- bin distribution preview (the *one* visual every Meteora UI shows)
- curve type selector (Spot / Curve / Bid-Ask — the three canonical DLMM strategies)
- fee tier chip (0.01% / 0.05% / 0.30%)
- pool selector (the user can't even *see* candidate pools — Aura picks them silently)
- IL preview / break-even price markers on a position chart
- model-confidence-per-pool view

A user configuring a strategy on Aura today is a user configuring an algorithm. A user configuring a strategy on a *smart* LP app should be a user configuring a *shape on a market*.

---

## 3. Redundancy + missing-surface audit

### 3.1 Redundancies to remove

| Redundancy | Where it shows up | Fix (rev 2) |
|---|---|---|
| Setup wizard ≡ Create Strategy | `/setup` vs `/create-strategy` | Single composer screen with `mode: { firstSetup, addNew }` prop. |
| "LIVE WALLETS" list on Profile | Profile + Bot detail | Live only on Bot detail. |
| `swap_screen.dart` model-stats view | Orphaned route | **Delete the file and the entire `lib/features/swap/` folder.** Founder verdict: ROC AUC and XGBoost version numbers are engineer telemetry, not user content — they don't belong anywhere in the app. The folder is also not needed for a future withdrawal screen (withdrawals already live in profile + strategy detail sheets). |
| Two parallel strategy wizards (`SetupScreen` + `CreateStrategyScreen`) | Both use the same step widgets but maintain duplicate orchestrator state | One `StrategyComposerScreen` with `mode` prop; `SetupScreen` becomes a thin wrapper that pre-fills first-run defaults. |
| Stat repetition between Home and Automate | Both | **Withdrawn (rev 2).** Founder is right: Home is a launchpad with summaries, Automate is the operator console. The repetition is intentional and correct. |
| Mode-named screen labels rebrand | "HOME" / "Automate" / "Intelligence" | **Withdrawn (rev 2).** Keep "Home". "Delegate" is long English for nothing. |

### 3.2 Missing surfaces (because we're a smart LP app, not a number-input app)

| Missing | Where it belongs | Why |
|---|---|---|
| **Bin distribution mini-chart** | Strategy composer (custom) + Bot detail + Position detail | The DLMM signature visual. Without it we don't communicate that we know what we're doing. |
| **Curve selector** (Spot / Curve / Bid-Ask) | Strategy composer | The 3 canonical DLMM liquidity shapes. Currently we silently pick one. |
| **Fee tier chip** | Strategy composer | DLMM pools have multiple fee tiers — we hide this. |
| **Pool browser** | Reachable from Home as a drill-in card, AND callable via Chat ("What pools are trending?") | "What pools is Aura currently considering?" — answers the trust question. |
| **Position price chart with bin range overlay** | Position detail | The reference UX for any LP product. |
| **In-range / Out-of-range status pill** | Position detail | The single most important live state of a DLMM position. |
| **Fees-earned-over-time series** | Position detail | Tells the LP whether they're still earning. |
| **Model confidence gauge** | Position detail (✅ exists as a linear bar; upgrade to a small radial gauge) | We have the data; the bar reads as a generic progress bar. A gauge reads as a *measurement*. |
| **Strategy templates row** | Top of step 0 in `/create-strategy` | "Conservative DLMM", "Aggressive Memecoin", "Stable Pair Grinder" — pre-baked configs. Removes the slider-tax for new users without removing the existing flow. |
| **Other Meteora products as discoverable links** | Inside Chat suggestions + a small "More ways to earn" row inside the Pool Browser | The other 7 Meteora products (DAMM v1/v2, DBC, Alpha Vault, Stake2Earn, Dynamic Vault, Dynamic Fee Sharing, Zap). v1 only links out to Meteora docs; v2 we integrate. **Not a separate "Earn" mode** — that would re-introduce the IA bloat. |
| **Risk dial in Home settings** | Profile → Risk preferences | Conservative / Balanced / Aggressive default — affects new bot defaults. |
| **Global kill switch** | Profile → Advanced | "Pause all operations". One tap, confirm sheet, all bots stopped. |
| **Aura's current state pill** | Top of Chat | Plain English — "Watching 12 pools · 2 bots running". Not engineer telemetry. |

### 3.3 Things that exist but are wrong-sized

| Thing | Currently | Should be |
|---|---|---|
| Splash duration | 3.8 s every launch | Full only on cold start (see §5.1 for the no-jitter implementation) |
| Settings overlay on Profile | 9-row grab-bag | 3 sections: Risk preferences · Notifications · Advanced |
| Onboarding card 2 vs card 3 | Both say "you set rules / limits" | Card 2 = the moat (model). Card 3 = control + kill-switch. (No "three modes preview" card — see §5.2.) |
| Identity card on Profile | Hero-sized | Compressed — the portfolio block is the hero |
| Custom strategy step | 12 sliders behind 4 collapsibles | Visual configurator (bin shape preview + curve selector + fee chip) on top, then collapsibles for guardrails + advanced |
| Stat boxes on Home | 2 boxes (Positions, Win Rate) | Keep them — they're glance summaries, appropriate for a launchpad |
| H2 collision in Home panel | "YOUR BOTS" and "Active Positions" both H2 | Demote "YOUR BOTS" to a section label; let "Active Positions" hold the H2 |

---

## 4. Information architecture (rev 2 — founder-corrected)

**Three top-level surfaces in the dock**: `Home · Chat · Automate`. This matches what's wired today — we are not re-ordering or renaming.

**Chat is the brain, not a peer.** It happens to live as branch 1 in the dock for now because the dock is the cleanest place to put it, but conceptually Chat is the *unified action layer* — every action elsewhere in the app should eventually be expressible as a Chat intent. The visual screens (Home, Automate, Position Detail, etc.) are *shortcuts* and *visualizations* of what Chat could already do via voice/text.

No Execute mode. No "Delegate" rename. No "Intelligence is ambient" gymnastics. The app already has a good shape; we're sharpening it, not rebuilding it.

### 4.1 Shell (always visible)

```
┌──────────────────────────────────────┐
│   ◇  ⟡  ◈                       [👤]  │  ← mode dock top-center, identity top-right (today's layout, kept)
│                                          │
│         [active mode content]            │
│                                          │
│           [voice/context btn]            │  ← bottom-center, hidden when on Chat
└──────────────────────────────────────┘
```

Changes vs today: **none structural.** The dock stays where it is. The voice button stays where it is. The identity glyph stays where it is. We're not adding a model-status pill to the shell either — it lives inside Chat (because the model is Chat's responsibility, not the shell's).

### 4.2 The 3 surfaces (no 4-layer matrix — that was over-engineering)

| Surface | What it is | Drill-ins |
|---|---|---|
| **Home** (`/`) | Launchpad. Portfolio summary + 2-each shortcuts to Bots and Positions + Trade History link. | `/position/:id`, `/history`, `/strategy/:botId`, `/profile`, `/fleet` |
| **Chat** (`/intelligence`) | The brain. Voice/text → strategy proposals, portfolio queries, actions, discovery. | Strategy params card → `/create-strategy`, action sheets, in-context Pool Browser |
| **Automate** (`/control`) | Operator console for bots. PnL header + bot list + create flow. | `/strategy/:botId`, `/create-strategy`, `/fleet` |

The 4-layer (Status / Control / Configuration / Forensics) framing from [interface-architecture.md](aura/docs/design/interface-architecture.md) is useful as a *mental model* for designing each screen, but we are not enforcing it as a literal navigation grid. The user thinks in screens, not layers.

---

## 5. Screen-by-screen target spec

For each, **delta from current**. Style rules deferred to §7 — assume the [AURA_MOBILE_DESIGN_SKILL.md](aura/docs/design/AURA_MOBILE_DESIGN_SKILL.md) rules apply throughout (surface stack, type scale, semantic radii, semantic colors).

### 5.1 Splash

- Cold start only: full sequence (the existing 3.8 s animation — unchanged, no jitter risk).
- Warm start (resumed within ~5 min, OR app already in memory): bypass `/splash` entirely; router redirects straight to the resolved destination.
- Implementation detail covered in §1.2 Splash audit — single static `_firstFrame` flag + `WidgetsBindingObserver` + one-line router redirect. Zero animation surgery, so zero risk of stutter.

### 5.2 Onboarding

- Card 1: **"Put your crypto to work."** Sub: *Aura deposits your SOL into top liquidity pools on Solana and earns trading fees for you — automatically, 24/7.* Visual: bin/curve illustration that suggests concentrated liquidity without naming it. "Powered by Meteora" appears small in sub-copy.
- Card 2: **"Backed by an AI model that's actually trained."** Sub: *We've studied tens of millions of real Solana trades to figure out which pools are worth entering — and when to leave. No guessing, no vibes.* Visual: a confident stat block (`v3 model · trained on 50M+ events`).
- Card 3: **"You're in control. Always."** Sub: *Set your spending limit, your risk level, and your stop-loss. Aura plays inside your rules — and you can pause everything with one tap.* Visual: a tactile slider + a kill-switch button.
- **Killed** the "three ways to deploy capital" preview card. The dock will be discoverable in-app.

### 5.3 Connect Wallet

- Headline: **"Connect your Solana wallet."**
- Sub-copy: *"This is how Aura signs trades and tracks your portfolio. Your wallet stays yours."*
- Below CTA: muted line — *"Works with Phantom, Solflare, and other Solana wallets."*
- Drop the stock onboarding image; replace with the Aura mark in the same surface treatment as splash.

### 5.4 Setup wizard / Strategy composer (unified)

Single `StrategyComposerScreen { mode }`. Three steps, but step 1 becomes visual.

- **Step 0 (Path & Mode)**: Two big cards on top half (Aura AI / Custom), two big cards on bottom half (Simulation / Live). Both choices made on one screen. No nested radios. **Above the path picker**: a horizontal scroll of 3–5 **Strategy Templates** (Conservative DLMM / Aggressive Memecoin / Stable Pair Grinder / ML Conservative). Tapping a template auto-fills sliders and skips to step 2.
- **Step 1 (Configure — visual)**:
  - Top: **Strategy Shape Preview** — a live bin distribution chart that updates as the user changes parameters.
  - Below shape: **Curve selector** chip row (Spot · Curve · Bid-Ask) — three icons + labels.
  - Below curve: **Fee tier chip row** (0.01% · 0.05% · 0.30%).
  - Below fee: **Bin range slider** with the shape preview reacting live.
  - Below: collapsible "Guardrails" section — position size, daily limit, profit target, stop loss. The 4 sliders that *every* strategy needs.
  - Below: collapsible "Advanced" — the remaining 8 sliders for power users.
- **Step 2 (Review & Deploy)**: One screen. Hero = the shape preview from step 1 (it carries through). Beneath it: the table of params. Bottom: deploy button (+ deposit sheet for live).

### 5.5 Home (kept)

Keep the dark-hero / light-panel layout, the 2-each Bots and Positions shortcuts, the stat boxes, and the Trade History link. Two changes only:

- **Zero state** (no bots, no positions): replace the lower panel with a 2-card vertical stack — **[ Talk to Aura ]** (opens Chat with starter prompt *"How should I start?"*) and **[ Create a strategy ]** (opens `/create-strategy`).
- **H2 collision fix**: demote the "YOUR BOTS" label to a section caption (12 sp, letter-spaced, tertiary color). Let "Active Positions" hold the only H2 in the panel.

### 5.6 Position Detail (the highest-leverage screen to upgrade)

- Top: status pill — `In Range` (green) / `Out of Range` (amber) / `Closed` (grey). Live.
- Below: pool name + LIVE/DB badge.
- Below: **Price chart** (line, 24h, full-bleed, no border) with two horizontal markers:
  - Entry price (dashed grey line)
  - Active bin price (solid accent line)
  - Bin range as a translucent vertical band
- Below chart: P&L (large, semantic color) + sub-line `+0.0123 SOL · +2.4%`.
- Below P&L: **Bin distribution mini-map** — horizontal bins, active bin highlighted, the user's deposited bins shaded.
- Below bin map: stat chips (Deposited / Fees / Hold time) — keep current.
- Below stats: **Fees over time** — a tiny bar series of fees collected per hour for the last 24h.
- Below: DETAILS (current text rows, keep).
- Below: **MODEL ASSESSMENT** — turn the linear progress bar into a small radial confidence gauge. Keep the explanatory text.
- Bottom: Close Position button (current).

### 5.7 Strategy / Bot Detail

- Top: status + name (current).
- Below: **PnL with 7-day sparkline** (new).
- Below: **Strategy Shape mini-card** — the same bin distribution preview from the composer, frozen at this strategy's params.
- Below: parameters (current — but grouped under collapsibles by section, not all 12 flat).
- Below: **Live Positions** — same row as today, but with inline mini bin indicator and a tap → Position Detail.
- Bottom controls: keep current Stop sheet (it's good).
- New thin link below the header: **"Started from Chat ›"** — only present when the bot was created from a chat thread. Returns to that thread.

### 5.8 Automate (kept)

Keep the screen as it is structurally. Two additions only:

- **Strategy Templates** appear at the top of `/create-strategy` step 0 (covered in §5.4) — not on the Automate list itself.
- **Empty state**: when no bots, replace the empty BOTS list with an illustrated card — *"No bots yet. Want Aura to set one up for you?"* + **[ Talk to Aura ]** + **[ Build it yourself ]**.

### 5.9 Chat

- Add a thin **state pill** at the top: plain English — e.g. "Watching 12 pools · 2 bots running". Tap → sheet listing what Aura is currently doing in human terms. **Not** ROC AUC / model version / engineer telemetry.
- Expand cycling suggestions into 4 categories: Strategy / Portfolio / Action / Discover.
- Round-trip with `/create-strategy` via a `chatThreadId` tag on the resulting bot.

### 5.10 Profile

- Identity becomes a 60 px header (avatar 48 px + name + address pill). Not a 100 px card with a shadow.
- **Portfolio** becomes the hero — Live SOL big, Simulation SOL secondary, both with a 7-day sparkline.
- Deposit / Withdraw buttons (current).
- Drop "LIVE WALLETS" list — moved to bot detail.
- Settings overlay collapses to:
  - **Risk preferences** (default risk profile, default position size)
  - **Notifications** (push / email / SSE)
  - **Advanced** (RPC, biometric, theme, version, support, sign out, kill switch)
- Add **Global Kill Switch** as the last item under Advanced — confirm with bottom sheet, stops all bots.

### 5.11 Fleet

- Add a per-row strategy mode dot (Aura AI / Custom / Hybrid).
- Everything else stays.

---

## 6. New screens we need

### 6.1 Pool Browser (drill-in from Home + callable from Chat)

- Reachable two ways: (a) a small "Pools Aura is watching ›" link on Home below the active positions, (b) Chat intent: *"What pools are trending?"* opens it inline.
- Lists current candidate DLMM pools the model is scoring right now, sorted by score.
- Each row: pool name · score · ML confidence · current TVL · 24h volume · model recommendation pill (Enter / Watch / Skip).
- Read-only in v1 — proves Aura is *thinking* even when it isn't trading.
- Bottom of the list: a small "More ways to earn on Meteora" row that links out to docs for DAMM v2, DBC, Alpha Vault, Stake2Earn, Dynamic Vault. v1 = link-out only; v2 = native integration. **No separate "Earn" mode** — acknowledged here, integrated later.

### 6.2 Decision Log (drill-in from a position or bot)

- Vertical timeline.
- Each entry: timestamp · model confidence · features that drove the decision · the action taken (entered pool X / exited pool Y) · outcome PnL.
- This is the receipt that justifies the 10% performance fee on Aura-AI bots.
- Reached from: bot detail header ("Why did this bot do what it did?" link) and position detail ("Why was this opened?" link).

That's it for new screens. **No Execute mode** (Jupiter swap can live as a Chat-callable action sheet — *"Swap 5 SOL for USDC"* — instead of a dedicated dock surface). **No standalone Earn mode** — the other Meteora products surface as discoverable links inside the Pool Browser.

---

## 7. Branding & visual rules (kept from rev 1, except rule 5 + rule 10)

1. **Numbers are the brand.** Big, monospace where appropriate, semantic color where appropriate. Never use a brand color where a semantic one is required (green/red for PnL is non-negotiable).
2. **Live data deserves motion.** Every live-updating number gets a subtle 200 ms color pulse on change. This is how the user trusts that the screen is alive.
3. **One H1 per screen, one H2 per panel.** No exceptions.
4. **Bin distribution chart is the visual signature.** Wherever DLMM is involved, that chart appears at the top, not buried in collapsibles. It's how we say "we know what we're doing".
5. **Mode color binding** (revised — we don't have Execute/Automate/Delegate any more; we have Home/Chat/Automate):
   - Home = neutral (white/text-primary on the dark hero; the hero IS the brand surface)
   - Chat = purple/accent (AI surface)
   - Automate = amber (autonomous operation)
   - Each surface's accent color tints its hero metric, its primary CTA, and its mode-dock active state. This is how a user *feels* which surface they're in without reading a label.
6. **Density tiers**: Hero (1 number, full width), Stat row (3–4 chips), Detail row (label + value pairs). Pick one per panel; never mix.
7. **Empty states are recruiting moments.** Every empty list gets an illustrated card + a primary CTA. Never just "No items.".
8. **Sheets, not modals.** All confirmations are bottom sheets with thumb-reachable buttons. The exception is the destructive global kill-switch confirm, which uses an explicit modal.
9. **Skeleton loaders, not spinners.** Spinners imply something is *wrong*; skeletons imply something is *coming*.
10. **Web2-readable headlines, technical sub-copy.** Headlines must pass *"could a non-crypto cousin read this and not feel stupid"*. "LP while you sleep" is out (too casual, wrong tone). "Sign with your wallet. Aura never holds your keys" is also out (locks us into a wallet architecture). "Your wallet stays yours" is in. Save AUC, ROC, XGBoost version numbers, bin step IDs, and other technical proof for sub-copy or sheet drill-ins, never for headlines.

---

## 8. Build order (when the visual pass starts)

We will not change everything at once. We will go in this exact order, each step reviewable on its own:

0. **Delete the legacy `lib/features/swap/` folder** and remove any dangling imports. Confirmed unrouted; not needed for withdrawals (those live in profile + strategy-detail sheets). Pure cleanup, no UI risk.
1. **Theme tokens & component library**: lock the surface stack, type scale, radii, surface accent colors as `ThemeExtension`s + a `BalanceDisplay` widget. No screen changes yet. (This is the foundation everything else compounds on.)
2. **Splash cold/warm-start split** — single `_firstFrame` flag + `WidgetsBindingObserver` + one router-redirect line. No animation surgery. Founder explicitly approved this fix, conditional on no jitter.
3. **Onboarding rewrite (3 cards, web2 voice)** — "Put your crypto to work" / "Backed by an AI model that's actually trained" / "You're in control. Always." Killed the modes-preview card.
4. **Connect Wallet copy + image swap** — "Connect your Solana wallet" + "Your wallet stays yours".
5. **Home: zero-state cards + H2-collision fix.** Everything else on Home stays.
6. **Position Detail — chart + bin map + in-range pill.** (Highest-leverage single screen.)
7. **Strategy composer — visual configurator (bin preview, curve selector, fee chip) + Templates row at top of step 0.**
8. **Bot Detail — PnL sparkline + Strategy Shape card + bin row indicators + "Started from Chat" link.**
9. **Profile — collapse settings, demote identity, promote portfolio, add global kill switch.**
10. **Chat — state pill (plain English) + 4-category cycling suggestions + chatThreadId tagging.**
11. **Automate empty state** — illustrated "No bots yet" card.
12. **Pool Browser** (drill-in from Home + Chat-callable).
13. **Decision Log** (drill-in from bot + position).
14. **Phantom Flutter SDK integration** as an alternative wallet provider on `/connect-wallet` (see §9.1).
15. **LP Agent endpoint integration + Zap-in/Zap-out** (see §9.2).

Ship 0 → 5 first — cheap, visible wins, low risk. 6 → 11 are the design investments that change how the app *feels*. 12 → 13 are the surface-area additions that change what the app *is*. 14 → 15 are the hackathon-aligned integrations.

---

## 9. Hackathon-aligned integrations

We are positioning Aura for two specific tracks. UI implications below — deeper integration plans live in separate technical docs.

### 9.1 Phantom (we built our own Flutter SDK)

**Story**: There is no official Phantom Flutter SDK. We built one ([phantom_flutter_sdk/](phantom/phantom_flutter_sdk/)) as a first-class citizen of Aura, then are open-sourcing it for the Phantom track. That's the narrative for the Colosseum Copilot positioning and for a Phantom-track submission.

**Confirmed by reading the Phantom code locally**: Phantom's SDKs (Flutter, React Native, browser, server) are **connection + signing primitives only**. They do **not** provide on-ramp / wallet funding (no MoonPay, no Coinbase, no buy-SOL flow). The closest thing in Phantom's own examples is *"please fund the wallet to continue"* + a polling loop — i.e. they expect funding to happen out-of-band. Searched [phantom_flutter_sdk/lib/src/](phantom/phantom_flutter_sdk/lib/src/) and [phantom-connect-sdk/](phantom/phantom-connect-sdk/): zero matches for `fund | onramp | moonpay | topup | buy.*sol`. Confirmed.

**UI implication for Aura**:

- On `/connect-wallet`, present **two** wallet-connection options (stacked cards):
  1. **MWA** (current) — "Connect with your installed wallet" (Phantom, Solflare, Backpack …)
  2. **Phantom Embedded** — "Use Aura's built-in Phantom wallet" — powered by our Flutter SDK. Best for users who don't have Phantom installed yet.
- **Funding remains Aura's responsibility, not Phantom's.** When a user is on Phantom Embedded with a 0 SOL balance, we surface a "Fund this wallet" sheet that copies the address, shows a QR, and lists the typical funding paths (centralized exchange withdrawal, in-app deposit from MWA wallet, or peer-to-peer). We do **not** promise an in-app on-ramp in v1.
- This is also why §5.3's connect-wallet copy reads "Your wallet stays yours" instead of "never holds your keys" — the embedded option is technically Aura-managed key material (encrypted, on-device), even if the UX feels non-custodial.

### 9.2 LP Agent (the [bounty.txt](bounty.txt) requirements)

**Bounty requirements (verbatim from [bounty.txt](bounty.txt))**:

1. Use one or more of LP Agent endpoints (<https://docs.lpagent.io/introduction>).
2. Use Zap In or Zap Out API inside the app.
3. Clear demo of how LP Agent is being used.

**Where LP Agent fits naturally in our UI**:

| LP Agent surface | Aura screen it powers | What changes |
|---|---|---|
| **Portfolio tracker endpoints** | Position Detail §5.6 + Home active positions list | Replaces / supplements our own position polling. LP Agent has $1T+ volume processed; their data depth on Meteora positions is better than what we'd build. Our position rows become richer (impermanent loss vs hold, fees-vs-IL ratio, time-weighted yield). |
| **Pool data endpoints** | Pool Browser §6.1 | Our model scores pools; LP Agent gives us the historical fee/volume/TVL series to enrich those scores client-side. |
| **Zap In API** *(required)* | Position Detail + Strategy Composer step 2 (deploy) + Chat action: *"Zap 5 SOL into this pool"* | A "Zap In" button on Pool Browser rows + an "Add to position" CTA on Position Detail. Single-token → LP entry, no manual swap-and-balance step. **This is where Zap is the most user-visible.** |
| **Zap Out API** *(required)* | Position Detail "Close Position" button | The existing close action becomes Zap Out under the hood — single-tap exit to user's preferred token (default SOL). |

**Demo path for the submission**: a 90-second screen recording — Home → Pool Browser (LP Agent data) → tap a pool → "Zap In 1 SOL" sheet (LP Agent Zap In API) → position appears on Home → open Position Detail (LP Agent portfolio tracker) → tap "Close" (LP Agent Zap Out API) → SOL returns to wallet. That's the bounty satisfied end-to-end on a single coherent flow.

**Bounty admin** (per [bounty.txt](bounty.txt)): register at <https://portal.lpagent.io/>, message Telegram **@thanhle27**, and add GitHub user **thanhlmm** as a collaborator if our repo is private. Reward: $120 premium credit × 6 months.

**Build order placement**: Pool Browser (§8 step 12) is where LP Agent's pool endpoints get their first surface. Zap In/Out integration lands at §8 step 15 — it touches Position Detail, Strategy Composer, and Chat, so it's done after those screens are stable.

### 9.3 Colosseum Copilot positioning

Not a UI change — a positioning note for the founder. Aura's pitch reads naturally as a **Colosseum Copilot** project ([colosseum.com/copilot](https://colosseum.com/copilot)): "institutional intelligence in your pocket" + a trained ML model + a Flutter mobile app + first-class wallet integrations + multiple Meteora earning surfaces. The UI we're describing here — web2-readable headlines, plain-English Chat state, kill switch, decision log — is what makes it *legible* to Copilot judges who aren't necessarily DeFi-native.

The one design rule we should hold *because* of Copilot exposure: **never put XGBoost, ROC AUC, or model version numbers in user-facing screen copy**. Engineer telemetry is a turn-off for Copilot judges and for non-quant users alike. It belongs in a sheet drill-in ("How does Aura decide?") for the curious, not in headlines.

---

## 10. What this document deliberately does NOT do

- Does not change a single line of code. Implementation is a separate pass, gated on founder approval of this map.
- Does not redesign the **Onboarding illustration art**, the **Splash logo animation**, or the **Rive assets** — those are out of scope of an *interface* audit.
- Does not specify backend changes. The model + extractors + bot engine are evolving in parallel; we are designing the surface that consumes whatever data shape they emit.
- Does not commit to v1 vs v2 cuts beyond the build-order in §8. We pull the line wherever the founder wants.
- Does not introduce "Execute" / "Delegate" rebrands (rev 1 did; rev 2 retracts).
- Does not introduce a 4-layer-per-mode navigation grid (rev 1 did; rev 2 retracts — it's a useful mental model, not a literal nav).

---

*Author: senior product designer + app architect, on April 18, 2026.*
*Rev 2: founder feedback applied same day — IA simplified, copy made web2-friendlier, Phantom + LP Agent + Copilot integrations added.*
*Inputs: [business-scope.md](aura/docs/business/business-scope.md), [interface-architecture.md](aura/docs/design/interface-architecture.md), [AURA_MOBILE_DESIGN_SKILL.md](aura/docs/design/AURA_MOBILE_DESIGN_SKILL.md), [MeteoraAg/docs/overview/home.mdx](MeteoraAg/docs/overview/home.mdx), [bounty.txt](bounty.txt), [phantom_flutter_sdk/](phantom/phantom_flutter_sdk/), [phantom-connect-sdk/](phantom/phantom-connect-sdk/), full read of every screen file under [aura/lib/features/](aura/lib/features/).*
