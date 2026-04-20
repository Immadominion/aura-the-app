# Aura — Business Plan

## Company Purpose

Aura is an autonomous capital execution platform for Solana. Users deploy capital, Aura operates it — executing trades, running strategies, and managing LP positions using machine learning trained on proprietary historical data.

---

## Problem

Capital on Solana is either idle or manually managed. Profitable LP strategies exist (proven: 77% win rate across 12,635 real positions on Meteora DLMM), but executing them requires 24/7 monitoring, custom scripts, and deep DeFi expertise. The tools that exist today are dashboards, Telegram bots, or raw terminal scripts — none of them turn intelligence into autonomous execution as a product.

---

## Solution

Aura gives users three levels of capital control from their phone:

- **Execute** — Instant swaps via Jupiter. One tap.
- **Automate** — User-defined rules that trigger trades when conditions are met.
- **Delegate** — Commit capital to Aura's ML model. It decides when to enter/exit LP positions on Meteora.

Non-custodial throughout. Users sign with their own wallet (Solana MWA). No private keys shared.

---

## Why Now

1. **Meteora DLMM** concentrates fees to active bins — LPs in the right position at the right time earn outsized returns. This creates a prediction problem that ML can solve.
2. **Old Faithful** (Solana Foundation's block archive) made 244 TB of historical data extractable for the first time. We decoded 50M+ DLMM transactions into structured training data. Nobody else has done this.
3. **Solana Mobile Wallet Adapter** enables non-custodial mobile execution — the user experience that makes this a product, not a script.

---

## Market

- **Meteora DLMM**: $300M+ TVL, fastest-growing AMM on Solana
- **Solana DeFi users**: ~2M monthly active wallets
- **Target segment**: Active Solana traders who want to LP but don't have time, tools, or confidence to do it manually
- **Adjacent**: Quant firms and analytics platforms who need structured Solana DeFi data (data API)

---

## Competition

Every competitor we've found (Gremory AI, Asteora, Helix, ShieldHedge, Condor) operates on **live Meteora API data only** — current state, no history. None train ML models. Most wrap an LLM around the Meteora API and call it "AI."

Aura's edge:

1. **Proprietary dataset** — 50M+ decoded historical transactions, 24 event types, full position lifecycle reconstruction
2. **Trained prediction model** — XGBoost on real LP outcomes, not prompt engineering
3. **Mobile execution** — not a Telegram bot or web dashboard

---

## Business Model

| Revenue Stream | How | When |
|----------------|-----|------|
| Performance fee | 10% of Delegate mode profits | On positive returns only |
| Pro subscription | $9.99/mo — unlimited bots, advanced analytics | Recurring |
| Swap fee | 0.15% integrator fee on Jupiter Ultra swaps | Every swap |
| Data API | Tiered access to historical DLMM data | Subscription |
| Intelligence API | ML predictions as a service | Bundled with data tier |

**Unit economics**: Break-even at ~15 Pro subscribers or ~$50K AUM in Delegate mode. Infrastructure cost ~$150/mo (Railway + Helius + S3).

---

## Architecture

```
Data Layer          →  Old Faithful Extractor → Parquet on S3
                       50M+ DLMM events, 24 types

Intelligence Layer  →  XGBoost model trained on position lifecycles
                       Served via FastAPI, <1ms inference

Execution Layer     →  Flutter app (Android) + Hono backend
                       MWA for signing, Jupiter for swaps,
                       DLMM SDK for LP positions
                       Per-bot encrypted keypairs (AES-256-GCM)
```

---

## Traction

- Production APK on GitHub releases
- Deployed backend on Railway
- ML model v3: 0.94 AUC on 1,600 samples (retraining on 100K+ Old Faithful lifecycles)
- Historical data pipeline processing epochs 544–950
- Superteam hackathon wins

---

## Vision

In five years, Aura is the execution layer for on-chain capital. Not just Meteora, not just LP — any DeFi strategy where historical data creates a prediction advantage. The data pipeline generalizes to any Solana program. The model framework generalizes to any structured trading decision. The mobile surface stays the same: your capital, operating.

---

## What  Is NOT

- **Not a DEX.** We aggregate via Jupiter — we don't run our own AMM.
- **Not a portfolio tracker.** Balance exists as context, not as the product.
- **Not a terminal.** No 12-panel layouts, no candlestick charts on the surface.
- **Not a social platform.** No leaderboards, no copy-trading, no following (v1).
- **Not a friendly crypto buddy.** No playful tone, no emojis, no lifestyle branding.

**is institutional intelligence in your pocket.**

---

## Competitive Position

| App | What They Are | What  Is |
|-----|--------------|--------------|
| **Phantom** | Wallet + basic swap | Execution engine with intelligence |
| **Jupiter Mobile** | Swap aggregator | Three modes of capital control |
| **Hawksight** | Custodial LP vaults | Non-custodial + user-defined strategies |
| **Kamino** | LP automation | ML-driven allocation + custom automation |
| **3Commas/Pionex** | CEX bots | On-chain, non-custodial, mobile-native |

**'s moat:** Mobile + non-custodial + codified automation + trained ML model on Meteora LP. No one else has all four.

---

## Success Metrics (v1 — 6 months post-launch)

| Metric | Target |
|--------|--------|
| MAU | 5,000 |
| Capital under delegation ( AI) | 500 SOL |
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
