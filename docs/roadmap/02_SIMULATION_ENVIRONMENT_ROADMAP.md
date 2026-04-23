# 02 — Simulation Environment Roadmap

> **Hard constraint:** this document contains **no code**. It is a logic specification. Every rule described here must be implemented identically in two places — the training-label generator and the paper-mode execution engine — so that the model is never trained on a world it will not encounter at inference time.

---

## 0. Why this document is the most important one

Every other workstream depends on a trustworthy simulator:

- **Training labels** come from simulated realized P&L over historical windows (doc 01).
- **Promotion gates** require a model to beat a baseline *in simulation* before it can touch live capital.
- **Paper mode** on the mobile app is the same engine fed with live Meteora state.
- **Post-mortem reconciliation** compares every live position's outcome against what the simulator predicted for the same entry — large divergence is a hard stop.

If the simulator is wrong, the model is wrong, the audit cannot catch it, and the product lies to the user. Therefore: one engine, one math, one set of edge cases, versioned like a protocol.

---

## 1. Scope and non-scope

### In scope

1. Deterministic **offline replay** over the Old Faithful parquet archive (historical P&L labelling and backtests).
2. **Paper mode** — same engine driven by live Meteora pool state and live price feeds, no on-chain transactions.
3. **Live shadow** — run the engine in parallel with real executions to produce a reconciliation delta stream.
4. A single, versioned **simulation specification** that the training pipeline and the runtime must both conform to.

### Out of scope (explicit non-goals)

- Simulating orderflow from market makers. We replay what happened, we do not generate counterfactual swaps.
- Simulating other protocols (Orca, Raydium CLMM). DLMM only.
- Multi-agent game-theoretic simulation. We model a single position against observed pool state.
- Tick-level CEX hedging. Delta hedging is a future workstream.

---

## 2. Current engine defects that this roadmap must close

Sourced from `aura/docs/technical/TRADING_ENGINE_AUDIT.md`. These are the correctness defects the new simulator must eliminate by design.

| # | Defect | Consequence if left unfixed |
|---|--------|-----------------------------|
| D1 | Fees accrue to all liquidity bins, not only the active bin | Overstates fee yield by 2-10× on narrow ranges |
| D2 | Pool-total fees used instead of the position's liquidity share | P&L independent of position size — nonsense |
| D3 | Protocol fee (5% of LP fees) not deducted | Systematic upward bias on every prediction |
| D4 | Exit P&L excludes fees | Model learns to avoid the trades that actually make money |
| D5 | Always-Spot strategy assumed | Curve/BidAsk distributions mislabelled |
| D6 | No impermanent loss reconstruction at close | Volatile pairs look more profitable than they are |
| D7 | Rent, priority fees, and Token2022 transfer fees ignored | Small positions look profitable when they are not |
| D8 | No chunked remove-liquidity modelling | Partial/stuck closures treated as full exits |
| D9 | No out-of-range time accounting | Missed the single most predictive failure mode |

The acceptance test for this workstream is a replay of 200 historical positions where every one of D1–D9 is demonstrably handled, with the reconciliation report attached to the release manifest.

---

## 3. Engine architecture (logical)

Three execution modes, one shared core.

```
                       ┌────────────────────────────┐
                       │    Simulation Core         │
                       │  (pure, deterministic)     │
                       │                            │
                       │  - Bin math                │
                       │  - Strategy shape resolver │
                       │  - Fee accrual rules       │
                       │  - IL reconstruction       │
                       │  - Cost model              │
                       └──────────────┬─────────────┘
                                      │
        ┌─────────────────────────────┼──────────────────────────────┐
        │                             │                              │
┌───────▼────────┐         ┌──────────▼─────────┐         ┌──────────▼─────────┐
│ Offline Replay │         │   Paper Mode       │         │   Live Shadow      │
│ (parquet)      │         │ (live state, no tx)│         │ (alongside real tx)│
└────────────────┘         └────────────────────┘         └────────────────────┘
```

The core is a **pure function of state and events**. It does not fetch, does not sign, does not sleep. It takes: an immutable pool-state snapshot stream, a position action log, and a cost schedule → it returns a reproducible P&L ledger and a structured event trace.

All three modes differ only in how they source input:

- Offline replay → parquet files from S3.
- Paper mode → live Meteora SDK reads + live price oracle.
- Live shadow → same inputs as paper mode, plus on-chain execution running in parallel.

---

## 4. Canonical event model

Every simulation run is reducible to a time-ordered event log. The engine processes these in strict causal order.

Event types, in priority order when timestamps tie:

1. **`PoolState`** — snapshot of active bin id, bin reserves, protocol fee rate, base fee, variable fee params, total liquidity in the position's range.
2. **`PositionCreate`** — wallet, pool, strategy shape, lower bin, upper bin, nominal deposit amounts.
3. **`AddLiquidity`** — bin distribution actually applied (may differ from requested shape due to rounding).
4. **`Swap`** — amount in/out, active bin before/after, fee captured by active bin, protocol fee carved out.
5. **`ClaimFee`** — fees transferred to position owner.
6. **`RemoveLiquidity`** — per-bin withdrawal amounts; may be chunked across many transactions.
7. **`PositionClose`** — final settlement, remaining dust returned.
8. **`PriceTick`** — external oracle price (Pyth / Jupiter mid) used for IL and USD P&L.

Determinism rule: given identical event inputs, the core must produce byte-identical output ledgers. Any non-determinism (clock, network, random) is forbidden inside the core.

---

## 5. Bin-accurate fee accrual (fixes D1, D2, D3)

The governing principles — stated in plain terms, not code.

### 5.1 Only the active bin earns fees on any given swap

DLMM routes a swap through the active bin until that bin's inventory is exhausted, then crosses to the next bin. Fees on a given swap increment belong **exclusively to the bin that was active for that increment**. A position earns fees on a swap increment only if:

- the active bin during that increment was inside the position's `[lower, upper]` range, **and**
- the position contributed liquidity to that specific bin.

### 5.2 Liquidity share within the active bin

Within the active bin, the position's fee share equals its liquidity contribution to that bin divided by the bin's total liquidity at the moment of the swap. This ratio must be recomputed at every swap event — it changes whenever anyone adds or removes in that bin.

### 5.3 Protocol fee deduction

The fee paid by the swapper is split: protocol takes a configurable percentage (currently 5%, read from pool state, not hardcoded), the rest is split among LPs in the active bin by their liquidity share. The simulator must read the protocol fee rate from the `PoolState` event at the time of the swap — it can change.

### 5.4 Dynamic fee component

DLMM's variable fee depends on recent volatility (`volatility_accumulator` + `volatility_reference`). The simulator must replay these state machines per pool, not assume a static base fee. The parquet archive stores the raw values needed to reconstruct them.

### 5.5 Fee accounting output

Each simulated position produces a fee ledger with, per swap increment: timestamp, bin id, gross fee, protocol fee, position share percentage, position fee credited, cumulative position fee to date. This ledger is the ground truth for the training label generator.

---

## 6. Strategy shape resolution (fixes D5)

DLMM positions can be deposited with three canonical shapes — Spot (uniform), Curve (bell), BidAsk (barbell) — plus arbitrary custom distributions. The simulator must:

1. Read the *actual* per-bin distribution from the `AddLiquidity` event, never assume Spot.
2. Classify the observed shape for feature engineering: compute a shape descriptor (skew, kurtosis, concentration ratio) and bucket it into Spot / Curve / BidAsk / Custom.
3. Preserve the full per-bin vector — downstream P&L math needs it.
4. For paper mode, the shape requested by the user is known up front; the simulator uses the requested shape but must re-derive the realized distribution after any rebalancing.

---

## 7. Impermanent loss reconstruction at close (fixes D6)

At `PositionClose`, the simulator must reconstruct the counterfactual HODL value to compute IL:

1. **Entry basket value** — value of tokens deposited at entry, priced at entry oracle mid.
2. **HODL value at close** — same token quantities, priced at close oracle mid.
3. **Realized basket at close** — token amounts actually withdrawn (including any rebalance-driven conversions during the position's life), priced at close.
4. **IL** = `HODL value − realized basket value`. Must be computed in USD terms using the same oracle series across entry and close.
5. **Net P&L** = `(realized basket value + claimed fees) − entry basket value − costs`. Fees and costs always in the formula. Never optional.

Oracle choice: Pyth if available for both tokens, else Jupiter quoted mid against USDC, else mark position as "unpriceable" and exclude from training (labelling gate).

---

## 8. Cost model (fixes D7)

Every simulated position must subtract:

1. **Rent** — position account, bin arrays opened by this position (prorated if shared). Closeable portion refunded at close.
2. **Priority fees** — per-transaction compute unit price × CU used. For offline replay, read from historical transaction metadata. For paper mode, use a configurable fee profile per urgency tier.
3. **Network base fee** — 5000 lamports per signature × signatures.
4. **Token2022 transfer fees** — if either token is a Token2022 mint with a transfer-fee extension, the fee is deducted at each transfer (deposit, withdraw, claim) per the mint's `transfer_fee_config`.
5. **Slippage** at add/remove. For adds, model the realized bin distribution given the actual active bin at submit time. For removes, model the tokens-out given current active bin.

All costs expressed in USD using the same oracle series as the P&L. Cost ledger is a first-class output, not buried inside aggregate P&L.

---

## 9. Edge cases (fixes D8, D9, plus a dozen others)

### 9.1 Chunked remove-liquidity

A full close may require many transactions (one per bin array group). The simulator must:

- Accept a partial-close state (position reduced but not closed) as a valid terminal state if the live client abandoned mid-close.
- Correctly prorate fees earned on the remaining liquidity during the chunked-close window.
- Produce a "stuck position" flag if close spans > N minutes without completion.

### 9.2 Out-of-range time

For every tick in the position's life, record whether the active bin is inside `[lower, upper]`. Aggregate:

- Total time in range.
- Longest single out-of-range streak.
- Fee-weighted in-range share (fees accrue only in range, so this must equal 1.0 by construction — a sanity check).

This is the most predictive single feature for failure mode classification.

### 9.3 Active bin slippage (error 6004 analogue)

If the active bin at add-time has moved beyond the position's intended range, the add would fail on-chain. The simulator emits an "entry failed" event and no position is opened. The training pipeline uses these as negative-entry examples.

### 9.4 Token2022 extensions

- Transfer fee — deducted per §8.4.
- Transfer hooks — flagged; position excluded if hook program is unknown to the allowlist.
- Permanent delegate / confidential transfer — flagged and excluded from training set (distributional difference too large).

### 9.5 Pool parameter changes mid-position

Base fee, protocol fee, bin step can change via governance. The simulator tracks parameter-change events and applies the new regime from that block forward.

### 9.6 Rebases, mint authority mischief

If either token's supply changes non-proportionally during the position's life (rebase, mint drain), the position is flagged "non-standard token dynamics" and excluded from training labels. A separate, smaller evaluation set collects these for robustness testing.

### 9.7 Missing data

If any input event is missing (gap in parquet archive), the position is marked "incomplete" and excluded from labels. Coverage metrics in the release manifest must show the exclusion count per run.

### 9.8 Clock skew between oracle and chain

Oracle ticks and swap events come from different clocks. Join rule: each swap uses the most recent oracle tick with `oracle_ts ≤ swap_ts` and `swap_ts − oracle_ts < max_staleness`. If staler than `max_staleness`, emit a "stale price" warning and interpolate linearly only for IL computation, never for fee math.

---

## 10. Paper mode specifics

Paper mode is the user-visible product surface for Tiers below "Delegate". It must:

1. Use the **same core** as the label generator. A divergence here is a model-drift incident.
2. Subscribe to the live Meteora pool state via the DLMM SDK (polling or websocket) and feed `PoolState` events into the core at the observed cadence.
3. Subscribe to the live price oracle feed and feed `PriceTick` events.
4. Simulate `AddLiquidity` / `RemoveLiquidity` by computing the transaction that would have been sent and applying it virtually. No RPC writes. No keypair use. No signature requests.
5. Produce a per-position live ledger identical in shape to the offline ledger, so the UI does not branch on mode.
6. Persist paper runs with the same schema as live runs, tagged `mode=paper`, so analytics and UI widgets are mode-agnostic.

Paper-mode guarantees:

- No network mutations. Ever. Enforced at the infrastructure boundary (paper-mode service has no signer credentials).
- Latency parity: paper mode uses the same pool-state polling cadence as live mode, so the model experiences comparable staleness.

---

## 11. Live shadow mode

Purpose: detect simulator–reality drift on positions the user actually opens.

Mechanism:

1. When a live position opens, the backend registers a shadow simulation with identical entry parameters.
2. The shadow runs in real time against the same pool-state stream.
3. At every position event (claim, rebalance, close), the shadow's predicted deltas are compared to the on-chain deltas.
4. A reconciliation report is emitted per position at close with signed residuals on fees, IL, costs, net P&L.

Thresholds (configurable):

- Mean absolute fee residual > X% of predicted fees → alert.
- Cost residual > Y% → alert.
- IL residual > Z% → alert.
- Any residual direction-flip (predicted profit, realized loss with |residual| > cost-of-capital) → page on-call.

Sustained drift halts model promotion automatically (see doc 01 promotion gates).

---

## 12. Reconciliation report (machine + human)

Every simulator run — label generation, backtest, paper run, shadow run — emits a structured reconciliation record:

```
run_id, core_version, cost_model_version, oracle_version,
input_digest, output_digest,
positions_total, positions_labelled, positions_excluded, exclusion_reasons{...},
sum_fees_gross, sum_fees_protocol, sum_fees_lp, sum_costs, sum_il, sum_net_pnl,
fee_residual_vs_onchain_pct,          // shadow/live only
cost_residual_vs_onchain_pct,         // shadow/live only
pnl_residual_vs_onchain_usd,          // shadow/live only
warnings[], errors[]
```

The `input_digest` is a hash of the concatenated event stream. Two runs with the same digest must produce the same `output_digest`. Divergence is a P0 bug.

---

## 13. Versioning and compatibility

Simulator artefacts are versioned as `core@X.Y.Z` where:

- **X (major)** bumps on any math change that alters historical labels. Requires full retrain and re-evaluation.
- **Y (minor)** bumps on additive features (new event type, new cost component) that do not change existing labels.
- **Z (patch)** bumps for bug fixes with identical outputs on the backtest suite.

Rules:

- Every model registered in the registry records the `core@X.Y.Z` it was trained against.
- At inference time, the runtime refuses to load a model whose core major does not match the running core major.
- The CI backtest suite is a fixed set of 200 historical positions covering all nine defect categories plus all seven edge-case categories. Any change to the core must produce the expected ledger on every one. Byte-for-byte.

---

## 14. Milestones

### S1 — Event Model & Replay Skeleton

- Finalize event schemas and parquet column mapping.
- Stand up deterministic replay harness with digest-based reproducibility check.
- Backfill 200-position CI suite with human-reviewed expected ledgers.
- **Exit gate:** identical digests across three consecutive runs on a pinned input.

### S2 — Correctness Pass (D1–D7)

- Active-bin-only fee accrual with liquidity share and protocol fee.
- Strategy shape from observed distribution.
- IL reconstruction at close.
- Full cost model (rent, priority fee, base fee, Token2022 transfer fee).
- **Exit gate:** CI suite passes; sum-of-fees reconciles to on-chain ledger within 0.5% for each position.

### S3 — Edge Cases (D8, D9 + §9.1–9.8)

- Chunked close handling.
- Out-of-range accounting.
- Entry-failure modelling.
- Token2022 extension handling.
- Parameter-change replay.
- Missing-data and stale-price handling.
- **Exit gate:** all seven edge-case categories have a dedicated CI fixture and pass.

### S4 — Paper Mode

- Live pool-state and oracle feed wiring into the same core.
- Ledger persistence schema unified across modes.
- Paper-mode service hardened with no-signer boundary.
- **Exit gate:** a paper run over 24 hours produces a ledger whose schema is byte-compatible with offline ledgers.

### S5 — Live Shadow & Reconciliation

- Shadow simulation pipeline.
- Reconciliation report generation and alerting.
- Automatic promotion halt on sustained drift.
- **Exit gate:** 50 consecutive live positions reconciled; fee residual < 1%, cost residual < 1%, no direction-flip false positives/negatives in the sample.

### S6 — Versioning and Governance

- Formal `core@X.Y.Z` versioning on artefacts.
- Model-registry integration (reject incompatible loads).
- Public change-log doc auto-generated from CI output.
- **Exit gate:** a major bump is exercised end-to-end — historical label regeneration, model retrain, promotion gate, rollback drill.

---

## 15. Guarantees the simulator must uphold

1. **Determinism** — same input stream ⇒ same output ledger, forever.
2. **Single source of truth** — training labels and paper/live predictions come from the same code path.
3. **No silent exclusions** — every dropped position is accounted for in the reconciliation record with a reason code.
4. **Honest costs** — rent, priority fees, Token2022, protocol fees, slippage: all present, always.
5. **Explainability** — every P&L number is reconstructible from the event ledger; no black-box aggregates.
6. **Version discipline** — no model loads against an incompatible core. No core ships without a CI green on the 200-position suite.

The simulator is the product's conscience. If it says a strategy loses money, the product does not run that strategy — no matter how confident the model is.
