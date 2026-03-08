# Sage — Business Scope

## Positioning

**Sage is your on-chain execution layer.**

It is not a trading app. It is not a dashboard. It is not a toolkit.

Sage is a financial execution engine for Solana — where your capital operates autonomously under your control.

### Internal Design Principle

> "Sage is where your capital operates."

Every screen, every interaction, every word in the interface must pass this test:
Does this show the user **what their capital is doing** and give them **control over how it behaves**?

If the answer is "no, this is informational clutter" — it doesn't belong on the surface.

---

## The Reframe

### What We Were Saying

"Sage is a mobile trading app on Solana that lets users buy tokens, automate custom strategies, and deploy AI-managed LP positions on Meteora."

### What We Say Now

"Sage is an autonomous capital allocator on Solana. It executes swaps, runs strategies, and deploys ML-driven LP — all from a single controlled surface on your phone."

The difference is not cosmetic. It changes:

- What we show (outcomes, not mechanics)
- How we show it (status, not dashboards)
- What we hide (configuration lives behind progressive disclosure)
- How the user feels (in control of a system, not operating a tool)

---

## The Problem (Reframed)

1. **Capital on Solana is idle or manually managed.** Users either park tokens or spend hours executing strategies by hand across fragmented tools and terminals.
2. **Intelligence exists but has no execution layer.** Profitable patterns are known (FreesolGames: 77% win rate, 12,635 positions). But there is no system that turns intelligence into autonomous execution on mobile.
3. **Existing tools expose mechanics, not outcomes.** Every app shows charts, order books, token lists. None of them answer: "Is my capital performing? What is it doing right now? How confident is the system?"

## The Opportunity

- Proven signal: FreesolGames' bot does **~$2K/month** with consistent win rates — the strategy works.
- XGBoost model trained on **200K+ data points** predicts profitable LP entry windows.
- Meteora DLMM dynamic fees enable net-positive high-frequency LP even with impermanent loss.
- Solana MWA enables non-custodial on-device signing — the user never gives up their keys.
- **No one has built this as a product.** It exists as scripts, bots, terminals. Not as a designed instrument.

---

## Three Modes of Execution

Sage is not organized by features. It is organized by **cognitive modes** — three distinct states of capital control.

### Mode 1 — Execute (Swap)

**Immediate execution.** The user wants to convert one asset to another, right now.

- Search-first: find token, set amount, confirm.
- No charts, no order books, no analytics on the surface.
- Route details, slippage, fees — all behind progressive disclosure.
- Powered by Jupiter Ultra API (RPC-less, gasless, sub-second).

**User's mental state:** "I want to do this now."

### Mode 2 — Automate (Strategies)

**Codified intent.** The user defines rules, and the system executes when conditions are met.

- Strategies are **living objects**, not configuration cards.
- Each strategy pulses, shows its state, reports its results.
- Templates for common patterns. Pro users build custom logic.
- Triggers: volume spike, price change, RSI threshold, new pair detection.
- Guardrails: max size, stop-loss, cooldown, concurrency limits.

**User's mental state:** "I want this to happen when X occurs."

### Mode 3 — Delegate (Sage AI)

**Delegated intelligence.** The user commits capital, and the ML system operates it.

- One surface: capital deployed, model confidence, market regime, PnL.
- Not a dashboard of positions. A single status panel.
- User controls the risk dial: Conservative / Balanced / Aggressive.
- Full transparency: every trade logged, every decision explained.
- Kill switch: pause or withdraw at any time.

**User's mental state:** "I trust the system. Show me how it's doing."

---

## Information Hierarchy

The interface is organized into four progressive layers. Most crypto apps collapse all four onto one screen. Sage separates them. That is why it feels clean.

### Layer 1 — Status

> "How is my capital performing?"

The default view for every mode. One dominant metric. One line of intelligence. One action.

- Execute: last swap result, current balance available.
- Automate: strategies running, net PnL.
- Delegate: capital under management, model confidence, regime.

### Layer 2 — Control

> "What is currently executing?"

Visible when the user drills in. Shows active state without overwhelming.

- Execute: pending swaps, recent history.
- Automate: live strategy status, recent triggers, recent actions.
- Delegate: active positions, entry/exit log, confidence timeline.

### Layer 3 — Configuration

> "How do I modify behavior?"

Behind a deliberate interaction. Settings, parameters, advanced tuning.

- Execute: slippage, gas priority, route preferences.
- Automate: edit triggers, adjust guardrails, create new strategies.
- Delegate: risk dial, deposit/withdraw, fee preferences.

### Layer 4 — Forensics

> "What exactly happened?"

Deep history. Full trade logs, model decision rationale, performance attribution.

- Available but never front-and-center.
- Export, filter, search.

---

## Revenue Model

| Stream | Mechanism | Notes |
|--------|-----------|-------|
| **Performance fee** | 10–15% of Sage AI profits | Only charged on positive returns |
| **Automation tier** | Free: 1 active strategy. Pro ($9.99/mo): unlimited | Recurring revenue |
| **Execution fee** | Integrator fee on Jupiter swaps (0.1–0.3%) | Volume-based |
| **Premium forensics** | Advanced logs, model insights, backtesting | Future upsell |

Non-custodial (MWA) = no custody of funds = reduced regulatory burden. Users sign every transaction with their own wallet.

---

## Architecture

### Mobile: Flutter (Dart)

- Android-first (iOS when MWA supports it)
- Riverpod for state, GoRouter for navigation
- flutter_animate for mode transitions, not for decoration

### Wallet: Solana MWA

- Non-custodial — private keys never leave the device
- User signs with Phantom/Solflare/any MWA wallet

### Execution: Jupiter Ultra API

- RPC-less — no infrastructure to maintain
- Gasless swaps, MEV protection, sub-second landing

### Intelligence: Self-hosted Python service

- XGBoost model served via FastAPI
- Market data from Helius webhooks + Meteora API
- Returns predictions + confidence to mobile app
- Position execution via DLMM SDK (TypeScript) on server

### Data: Helius

- DAS API for balances, metadata
- Webhooks for real-time transaction monitoring
- Enhanced parsing for forensics layer

---

## Who Uses Sage

| Persona | Relationship to Capital | Primary Mode |
|---------|------------------------|--------------|
| **Allocator** | Deploys capital, checks outcomes weekly | Delegate |
| **Operator** | Defines rules, monitors execution daily | Automate |
| **Executor** | Needs to move assets now | Execute |
| **Hybrid** | All three depending on context | Mode switching |

Note: These are not "user types" — they are **states a single user moves between**. The same person allocates, operates, and executes at different times.

---

## What Sage Is NOT

- **Not a DEX.** We aggregate via Jupiter — we don't run our own AMM.
- **Not a portfolio tracker.** Balance exists as context, not as the product.
- **Not a terminal.** No 12-panel layouts, no candlestick charts on the surface.
- **Not a social platform.** No leaderboards, no copy-trading, no following (v1).
- **Not a friendly crypto buddy.** No playful tone, no emojis, no lifestyle branding.

**Sage is institutional intelligence in your pocket.**

---

## Competitive Position

| App | What They Are | What Sage Is |
|-----|--------------|--------------|
| **Phantom** | Wallet + basic swap | Execution engine with intelligence |
| **Jupiter Mobile** | Swap aggregator | Three modes of capital control |
| **Hawksight** | Custodial LP vaults | Non-custodial + user-defined strategies |
| **Kamino** | LP automation | ML-driven allocation + custom automation |
| **3Commas/Pionex** | CEX bots | On-chain, non-custodial, mobile-native |

**Sage's moat:** Mobile + non-custodial + codified automation + trained ML model on Meteora LP. No one else has all four.

---

## Success Metrics (v1 — 6 months post-launch)

| Metric | Target |
|--------|--------|
| MAU | 5,000 |
| Capital under delegation (Sage AI) | 500 SOL |
| AI win rate | > 65% |
| Active automations | 1,000 |
| Daily execution volume | $50K |
| Pro tier subscribers | 200 |
| App rating | 4.5+ |

---

## Risk Register

| Risk | Impact | Mitigation |
|------|--------|------------|
| ML model underperforms live | Capital loss, trust destroyed | Conservative defaults, transparent PnL, kill switch |
| MWA adoption too small | Low user base | Jupiter Ultra works without MWA for some flows |
| Regulatory scrutiny on AI trading | Compliance overhead | Non-custodial, clear disclosures, no fund custody |
| Solana congestion | Failed transactions | Jupiter Beam + retry logic + Helius premium RPC |
| Model overfitting | Poor generalization | Online learning, continuous retraining, manual override |

---

## Design Imperative

The interface must feel like a **device**, not an **app**.

- Dark mode is the primary experience.
- Typography is bold, not decorative.
- Shapes are sharp, not toy-like.
- Animation indicates state change, not personality.
- Microcopy is precise, not cute.
- Whitespace is structural, not aesthetic.

The vibe: **Controlled power.** An execution system powered by intelligence.

Not a friendly fintech. Not a degen terminal. Not a dashboard.

A financial instrument.
