# Aura — Production Roadmap (Executive Overview)

> **Date:** April 17, 2026
> **Scope:** The system (backend, simulation, mobile, infra, subscription) is production-grade from day one. Only the **first model** is treated as an MVP / calibration artifact. Everything around it is built to survive scrutiny.
> **Audience:** Engineering, product, ops. Investors should read the business scope separately.

---

## 1. Framing — What "MVP" Actually Means Here

A single sentence we keep repeating:

> **The model is the MVP. The platform is not.**

Concretely that means:

| Layer | Posture |
|-------|---------|
| ML model v1 (the thing we ship first) | Baseline, rough, honest. Used primarily to bootstrap the simulation, calibrate feature importance, and feed the UI with *directionally correct* signals. Not used to place unattended live capital at launch. |
| Simulation environment | Production-grade. Deterministic replay over Old Faithful parquet data with bin-accurate fee accrual. This is what we will show users, auditors, and ourselves. |
| Backend platform | Production-grade microservices, observability, secrets, isolation, rate limiting, kill switches. |
| Mobile app | Production-grade. Non-custodial flows, clear state machines, offline-tolerant. |
| Subscription & billing | Wired in from day one, even if free for early users. No retrofits later. |

We are not shipping a "prototype that happens to take money." We are shipping a platform that happens to run an early model.

---

## 2. What Already Exists (Audit Snapshot)

Pulled from [aura/docs/technical/TRADING_ENGINE_AUDIT.md](../technical/TRADING_ENGINE_AUDIT.md), [aura/docs/technical/BACKEND_SYSTEM_DESIGN.md](../technical/BACKEND_SYSTEM_DESIGN.md), and inspection of [lp-bot/](../../../lp-bot/) and [ml-pipeline/](../../../ml-pipeline/).

| Area | State | Quality |
|------|-------|---------|
| Old Faithful extraction | Running on Hetzner, 33+ epochs, enriched parquets on Contabo S3 | Good, continues |
| ML model v3 (XGBoost) | 12 features, ~3,466 samples, volume-proxy labels | **Subpar** — tiny training set, proxy labels, over-fit risk |
| Feature engineering v2 | Windowed aggregates over trades only | Incomplete — ignores AddLiquidity / RemoveLiquidity / ClaimFee events |
| lp-bot trading engine | CRON scanner + rule-based scoring + simple executors | Works, but has the 5 flaws in the audit (fee P&L, active-bin accrual, share, protocol fee, strategy) |
| lp-bot simulation | Live-RPC only, no historical replay | Inadequate — cannot validate models offline |
| Wallet architecture | Per-bot AES-256-GCM encrypted keypairs, isolated, already migrated off legacy wallet | Good foundation |
| Backend (aura-backend) | Hono + Postgres sketched, bot orchestrator design | Designed, partially implemented |
| Mobile app (Flutter) | Flows exist, live trading flag off | UI needs reshaping once model semantics mature |
| Subscription | Not wired | Missing |
| Observability / Ops | Minimal | Missing |

This roadmap is how we fix all of that.

---

## 3. Roadmap Documents

Each document is a standalone plan. They reference each other but can be executed by separate people / workstreams.

| # | Document | Purpose |
|---|---|---|
| 00 | This file | Executive framing, principles, workstream map |
| 01 | [Model Training Roadmap](01_MODEL_TRAINING_ROADMAP.md) | How we go from 3k-sample proxy model to a real, PnL-labelled, versioned model — with v1 as the honest MVP |
| 02 | [Simulation Environment Roadmap](02_SIMULATION_ENVIRONMENT_ROADMAP.md) | Deterministic offline replay engine. **Pure logic spec, no code.** This is what validates every model and every strategy change before anything touches mainnet |
| 03 | [Backend Infrastructure Roadmap](03_BACKEND_INFRASTRUCTURE_ROADMAP.md) | Microservice boundaries, AWS posture, secrets, isolation, kill switches, observability |
| 04 | [Mobile UI Roadmap](04_MOBILE_UI_ROADMAP.md) | How the Flutter surface changes as model capabilities, simulation replays, and subscription tiers come online |
| 05 | [Subscription & Monetization Roadmap](05_SUBSCRIPTION_AND_MONETIZATION_ROADMAP.md) | Tier design, entitlement enforcement, billing integration, grace states, without activating charges at launch |
| 06 | [LP Agent Integration Roadmap](06_LP_AGENT_INTEGRATION.md) | How and where we integrate LP Agent's discovery and Zap APIs to unlock the bounty track without creating a hard dependency |

---

## 4. Guiding Principles (Non-Negotiable)

These apply to every document below.

1. **Non-custodial by construction.** No flow can assume the backend holds the user's primary wallet private key. Bot keypairs are per-bot, encrypted at rest, revocable, and spend-capped on-chain.
2. **Every write path has a kill switch.** Backend, per-bot, per-user, global. Kill switches are enforced at the service boundary, not only at the UI.
3. **Every model decision is reproducible.** We version the model, the features, the feature code, the data snapshot (S3 prefix + epoch range), and the threshold. A prediction from six months ago must be re-derivable from persisted artifacts.
4. **Simulation results are first-class citizens.** Every model and every strategy change ships with a replay report. No replay = no promotion.
5. **Defaults are conservative.** Size caps, cooldowns, slippage, daily-loss limits default to the low end. Users opt *up*, not *down*.
6. **Edge cases are named, not implied.** Out-of-range positions, chunked `removeLiquidity` failures, Token2022 transfer fees, RPC failures, concurrent signing, account rent exhaustion — each has an explicit handler path in the design docs.
7. **Secrets live in a secret manager.** Never in env vars committed anywhere, never in logs, never in crash dumps. Encryption master keys are ephemeral in memory and rotated.
8. **Observability is not optional.** Every external call, every on-chain write, every model inference is traced with a correlation id. Without this, we cannot debug a real user losing real money.
9. **One source of truth per concept.** A position's state lives in Postgres (+ on-chain for verification). Config lives in Postgres. Model artifacts live in S3 with a metadata row. No JSON files on disk as authoritative state.
10. **Compatibility budget.** We assume v1 of the model is wrong in at least one way we haven't noticed. Every consumer must accept a new model version without redeploy.

---

## 5. Workstream Sequencing (High Level)

The following is the *sequence the platform will mature in*, not individual sprint tasks. Each workstream has its own internal milestones in its document.

```
Phase A — Foundations (simulation + infra shell)
├── Simulation engine spec → reference implementation behind a Go / Node service
├── Backend microservice boundaries cut: auth, bot-control, ml-inference, market-data, sim, billing
├── Shared observability (OpenTelemetry traces, structured logs, metrics)
└── Encrypted keypair vault hardened (KMS-backed master key, audit log)

Phase B — Model v1 (the MVP model)
├── Label reconstruction pipeline (positions → realized fees + IL + rent)
├── Feature set expanded from trade-only to trade + LP-lifecycle
├── Train v1 on ≥10x more samples, time-series split
├── Ship behind a "paper / sim-only" flag — NOT authorized for live delegation yet
└── Model serves the UI as advisory signal, validated nightly in simulation

Phase C — Controlled live execution
├── Circuit breakers + per-bot daily caps wired end-to-end
├── Live executor gated by simulation-equivalence test on each model release
├── Progressive size ramps: paper → $25 caps → user-chosen
└── Subscription entitlement checks on every execute path

Phase D — LP Agent integration & public discovery
├── Pool discovery surface uses LP Agent endpoints (see doc 06)
├── Zap-in / Zap-out paths available alongside our own DLMM SDK path
├── Position dashboard optionally enriched by LP Agent open-positions feed
└── Bounty submission package

Phase E — Model v2 and beyond
├── Online / nightly retraining loop
├── Per-pool regime classifier
├── Portfolio-level risk overlays
└── Strategy-adaptive bin shape selection (Spot / Curve / BidAsk)
```

Phases overlap in calendar time. What matters is the dependency chain: **no live execution before simulation agrees with reality, no subscription charges before entitlements are enforced, no model promotion without a replay report.**

---

## 6. Definition of Done for "Launch"

We will say we have launched when all of these are true:

- [ ] Every user-visible action has a corresponding simulated equivalent the user can run first.
- [ ] Every live write is preceded by a fresh simulation on the last 7 days of data and a pass/fail gate.
- [ ] A fresh install of the mobile app can sign in, fund a bot, run paper, upgrade to live, and cleanly exit all positions without support.
- [ ] Every microservice has health, readiness, metrics, and a runbook.
- [ ] Secrets rotate without a redeploy.
- [ ] Kill switches have been drilled: one-tap mobile, admin console, and scripted emergency stop all produce the same end state within 60 seconds.
- [ ] Subscription tiers are enforced at the API boundary, not only in the UI.
- [ ] Model v1 has a public, reproducible replay report for the last 30 days of data.
- [ ] A full security review has been passed (doc 03, section on security).

Nothing in this list is "nice to have." Anything unchecked is a launch blocker.

---

## 7. What We Deliberately Defer

To keep the scope honest, these are explicitly **out of scope for the first live release** and live in their own future docs:

- Copy-trading, social leaderboards, shared strategies.
- Cross-chain execution.
- Custodial vaults.
- Automated tax reporting.
- Non-Meteora venues (Orca Whirlpool, Raydium CLMM) — the architecture supports them but we don't ship them.

Deferring these is not a weakness; it's what lets everything above actually be production-grade.
