# Model Training Roadmap

> **Purpose:** Move from the current volume-proxy XGBoost trained on ~3,466 samples to a realistic, PnL-labelled, versioned model pipeline. v1 is the MVP; the *pipeline around it* is permanent.
> **Source of truth for data:** Old Faithful parquet archive on Contabo S3 (33+ epochs and growing, continuous extraction on Hetzner).

---

## 1. What Is Actually Wrong With the Current Model

From [ml-pipeline/ML_PIPELINE_STATUS.md](../../../ml-pipeline/ML_PIPELINE_STATUS.md) and [aura/docs/technical/TRADING_ENGINE_AUDIT.md](../technical/TRADING_ENGINE_AUDIT.md):

| Defect | Detail | Consequence |
|---|---|---|
| Tiny dataset | 3,466 samples, 162 positive (4.7%) | Any reported AUC is fragile; random data reshuffles change rankings |
| Wrong label | "Future volume ≥ $100 AND trades ≥ 2 in next 60 min" | We're predicting *activity*, not *LP profitability*. The bot then earns fee on activity in pools that may still be net-negative for an LP after IL. |
| Trade-only features | Aggregated swap volume / fee windows | Ignores the LP side of the market entirely: AddLiquidity density, RemoveLiquidity timing, ClaimFee cadence, bin-traversal patterns |
| Pool coverage | Limited to what Dune exposed cheaply | Survivorship bias — only pools that existed long enough to hit Dune's aggregations |
| No time-aware split | Random train/test | Leaks future information; AUC is inflated |
| Single point-in-time inference | One-shot score | No sense of decay; a high score from 2h ago is treated like a score from 10s ago |

Fixing these is the roadmap.

---

## 2. Design Principles for the Model Pipeline

1. **Labels come from reality, not proxies.** A training label is the realized, fee-inclusive, IL-adjusted, rent-adjusted return of a *hypothetical LP position* opened at time T with a defined bin range and size, held for a defined horizon, and closed. Nothing less.
2. **Time-series splits, always.** Train on older epochs, validate on a blind holdout of later epochs. Never random-split.
3. **Multiple horizons.** We learn separate models (or a multi-head model) for 30 min, 2 h, and 8 h holds. The product can choose.
4. **Reproducibility.** Every artifact is tied to: feature code git hash, training data S3 prefix, epoch range, model hyperparameters, threshold, and metric report.
5. **No silent re-labelling.** If we change the label definition, the major version number bumps. Consumers cannot confuse v1.label-A with v1.label-B.
6. **Model family is not sacred.** We will start with gradient-boosted trees (XGBoost or LightGBM) because of the imbalanced-tabular track record described in [Aura_ Building an ML Trading Bot.txt](../../../Aura_%20Building%20an%20ML%20Trading%20Bot.txt). We *do not* commit to any architecture beyond v1.
7. **Conservative in production.** A positive prediction never automatically places capital. It feeds a scorer; the scorer plus rule-based gates decides.

---

## 3. The v1 Pipeline (MVP Model)

This is the honest baseline we ship first.

### 3.1 Data Window

- **Source:** All enriched epochs on `s3://dlmm/epoch-*` with prices filled.
- **Initial window for v1:** All currently extracted epochs, held-out block-aligned for validation (e.g. oldest 75 % train, most recent 15 % validation, newest 10 % test, by epoch, not by row).
- **Growth:** Each new extracted epoch appears in the next training cycle automatically via a manifest file in S3.

### 3.2 Event Joining — The Position Lifecycle

We reconstruct LP positions by joining these parquet tables on `lb_pair`, `owner`, and position account:

| Event | Role in label |
|---|---|
| `PositionCreate` | Marks the start of a position lifecycle |
| `AddLiquidity` | Capital going in (deposited X and Y amounts, bin range) |
| `Swap` | Feeds the fee accrual simulation (see doc 02) and gives the price path |
| `ClaimFee` | Realized fees taken out |
| `ClaimReward` | Any farm rewards (included in gross return) |
| `RemoveLiquidity` | Capital going out (with remaining X and Y amounts) |
| `PositionClose` | Marks end of lifecycle |

A lifecycle is a sequence ordered by slot: open → add → (adds / swaps observed / partial removes / claims)* → close.

For each completed lifecycle we compute **realized P&L**:

```
realized_value_out = (X_out * price_x_out) + (Y_out * price_y_out) + claimed_fees_usd + claimed_rewards_usd - rent_consumed
realized_value_in  = (X_in  * price_x_in)  + (Y_in  * price_y_in)
realized_return    = (realized_value_out - realized_value_in) / realized_value_in
```

Note: prices at deposit and withdrawal are taken from the enriched swap stream closest in time (already in the parquet as the `price` column).

### 3.3 Label Definition (v1)

We do not train on "was this LP profitable." We train on:

> At time T, for pool P, considering a spot-distributed position of width W centered on the active bin and held for horizon H, what is the expected realized return net of fees, IL, and rent?

v1 simplifies to a **binary label** first (to keep the MVP honest):

- `y = 1` if the simulated return over horizon H exceeds a threshold chosen from empirical quantiles of positive outcomes (e.g. top quartile).
- `y = 0` otherwise.

Later versions (v2+) regress the return directly.

Crucially: the label is computed by the **simulation engine** (doc 02), not heuristically. This gives us a single source of truth — whatever the bot will use for forward inference in paper mode is the same engine that labelled training data. No train/serve skew.

### 3.4 Feature Set (v1)

Split into families. Each family has a dedicated feature module so they can evolve independently.

| Family | Examples | Why it matters |
|---|---|---|
| Volume windows | 5 min, 30 min, 1 h, 4 h, 24 h trade volume in USD | Current signal, already proven useful |
| Fee windows | Same windows, for fee USD | Fees are the actual revenue |
| Fee efficiency | Fee per $ liquidity per hour | Captures "quality" of volume |
| Bin activity | Unique bins touched per window, bin-traversal rate, active-bin change rate | Differentiates grinding pools from one-sided drives |
| LP density | AddLiquidity count and $ amount per window, unique LPs per window | High density = lower future per-LP share |
| LP churn | RemoveLiquidity count, median time-in-position | Short-lived LP behaviour signals toxic flow / exit cascades |
| Fee-claim cadence | ClaimFee events per window | Indirectly signals realized earnings |
| Pool structural | bin_step, base_fee, volatility accumulator if available, pool age | Explains why two pools with similar volume have different fee capture |
| Pair context | Quote token family (SOL / USDC / meme), token mint creation age | Token2022 traps, fresh-launch regimes |
| Time context | hour-of-day, day-of-week (UTC) | Solana activity is seasonal |

**Explicit non-features for v1:** no on-chain price oracles outside the enriched parquet, no Twitter / social features, no external macro. v1 stays inside what we own.

### 3.5 Model Family

- **v1:** LightGBM or XGBoost classifier with `scale_pos_weight` tuned to the actual empirical imbalance.
- **Calibration:** Isotonic or Platt scaling on the validation fold so the output is a well-calibrated probability, not a rank score.
- **Output shape:** For each (pool, timestamp) we emit `{p_profit_30m, p_profit_2h, p_profit_8h, model_version, feature_hash}`.
- **Inference latency budget:** < 5 ms per pool on CPU so the scanner can evaluate hundreds of candidates per tick.

### 3.6 Evaluation

We measure and persist, for each training run:

- ROC AUC, PR AUC, expected calibration error, Brier score — on the time-sorted held-out set only.
- **Simulated portfolio metrics** from doc 02: hit rate at threshold θ, average realized return, worst-case drawdown, mean hold time, rent cost share, "would-have-entered crowded bin" count.
- A simulated equity curve over the validation window, so humans can eyeball regime behaviour.

A model run that improves AUC but worsens the simulated equity curve **does not** get promoted. AUC is diagnostic, not a promotion criterion.

### 3.7 Promotion Gates (v1 and every version after)

A model is promoted from `staging` to `paper` to `live` only when:

| Gate | Requirement |
|---|---|
| Data provenance | Training manifest references only epochs ≤ validation_cutoff |
| Reproducibility | Re-running the pipeline from the manifest produces bit-identical artifacts within tolerance |
| Calibration | ECE ≤ 0.05 on held-out |
| Simulation return | Median realized return over a 30-day walk-forward replay is strictly positive after fees, IL, and rent |
| Drawdown ceiling | Max drawdown over replay ≤ the drawdown the previous promoted model produced on the same window + small tolerance |
| Regime breadth | Replay covers at least three distinguishable volatility regimes (enforced by feature-based clustering on validation days) |
| Sign-off | Human review recorded in model registry with reviewer identity and comment |

Live promotion additionally requires a Phase C readiness check from doc 00.

---

## 4. Training Artifacts and Versioning

Every run produces a deterministic bundle stored in S3 under `s3://aura-models/<family>/<semver>/`:

| File | Contents |
|---|---|
| `manifest.json` | Git SHA of training code, feature code hash, epoch range, label config, splits, seed |
| `model.bin` | Serialized booster |
| `calibrator.json` | Isotonic / Platt parameters |
| `features.schema.json` | Names, dtypes, windows, default fill values |
| `thresholds.json` | Per-horizon decision thresholds derived from validation PR curves |
| `eval_report.json` | All metrics |
| `sim_report.json` | Full replay from doc 02 |
| `sim_equity_curve.parquet` | Full per-trade replay log |
| `sha256.txt` | Hashes of all of the above |

A Postgres table `model_registry` holds one row per artifact with lifecycle state (`staging`, `paper`, `live`, `retired`). Consumers resolve by `state = 'live'` for the relevant horizon family — they never hardcode a path.

---

## 5. The Roadmap (Ordered, Not Dated)

### Phase M1 — Data readiness (foundation)

- Build the lifecycle joiner: given an epoch range, emit one row per completed LP position with deposits, withdrawals, claims, and realized USD P&L.
- Stand up the feature generator as a pure function of `(pool, timestamp, window)` producing a feature vector deterministically from the parquet archive.
- Validate lifecycle reconstruction on a sampled set of known wallets by comparing our reconstructed P&L to the Meteora API's own position history where it overlaps.

**Done when:** We can produce a CSV / parquet `(pool, t, features..., realized_return_for_horizon_h)` for any historical moment in the archive, on demand, reproducibly.

### Phase M2 — v1 model training

- First full run of the v1 pipeline end-to-end.
- Generate the simulation replay report.
- Store artifacts in the registry under `staging`.
- Document known weaknesses in a public `v1_caveats.md`.

**Done when:** Artifact bundle exists, simulation report is positive over at least a 30-day held-out window, humans have signed off on the caveats doc.

### Phase M3 — Serving integration

- `ml-inference` microservice (see doc 03) loads the `paper` model by `model_registry` lookup, not by filename.
- Response includes the model version, so downstream logs carry the exact version that made each decision.
- Canary inference for 48 h alongside the old predictor, comparing outputs on every scanned pool; deviation report filed nightly.

**Done when:** Paper trading reads v1, emergency rollback is a single flag flip, and the canary report shows no inference drift.

### Phase M4 — Paper trading validation

- Every user on the platform gets a paper-mode bot running v1 against live market data through the simulation engine's paper mode.
- Metrics: hit rate, realized return distribution, drawdown, mean hold, number of stuck positions.
- Side-by-side comparison against the previous heuristic scorer across the same opportunities.

**Done when:** 14 consecutive days of paper trading show the model matching or beating the heuristic, with no unexplained tail events.

### Phase M5 — Controlled live execution

- Model state is promoted to `live` under the promotion gates above.
- Delegate mode becomes opt-in with tight caps (see doc 03 on circuit breakers).
- Weekly model review meeting produces a "continue / pause / retrain" decision, logged in the registry.

**Done when:** Live executions are gated, logged, reviewed, and reconcilable end to end with zero unexplained PnL delta vs. simulation.

### Phase M6 — v2 and the continuous loop

- Move from classification to calibrated regression for expected return.
- Add per-pool regime classification as a separate model that routes to strategy choice (bin width, shape).
- Nightly retraining on the rolling window with automatic promotion *only if* the promotion gates pass.
- Online-learning experiments restricted to a shadow model; never auto-promoted.

**Done when:** We can add a new epoch, retrain, and ship — or decline to ship — without manual pipeline work.

---

## 6. Explicit Non-Goals for v1

These are tempting but deferred to v2+ and called out so nobody quietly smuggles them in:

- Deep sequence models (LSTM, Transformer). The sample count and regime non-stationarity make them a poor v1 bet.
- Reinforcement learning on LP actions. Reward shaping on a non-stationary market is a research project, not a ship goal.
- Using user trades as training signal. Creates feedback loops and privacy issues. Deferred until we have explicit consent flow and a shadow model.
- Multi-chain features. Solana only.
- LLM "explanations" of model outputs. We will expose feature importances from the booster; that is enough.

---

## 7. Risks and Mitigations

| Risk | Mitigation |
|---|---|
| Label noise from IL reconstruction (thin-bin pools) | Filter lifecycles shorter than a minimum and pools below a minimum liquidity; log coverage of what we filter |
| Regime shift between training and live | Rolling retrain with walk-forward validation; alert if live feature distributions diverge from training |
| Leakage via price lookups | Strict enforcement that features at time T can only see events with `block_time ≤ T` |
| Survivorship bias | Include pools that died during the window as long as they had activity in the window; do not silently drop them |
| Under-represented rare pairs | Inverse-frequency weighting, documented, validated |
| Over-fit thresholds | Thresholds chosen on validation fold, evaluated on test fold, never tuned on test |
| "Model works in sim, fails live" | Simulation is the *same* engine that paper-mode runs; discrepancies go to doc 02's reconciliation report |
