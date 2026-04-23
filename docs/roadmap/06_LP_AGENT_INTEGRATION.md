# 06 — LP Agent Integration Roadmap

> LP Agent is a third-party DLMM intelligence service with pool discovery, position tracking, and Zap-style single-asset deposit/withdraw primitives. Aura integrates it behind a stable internal abstraction so that LP Agent capabilities are available to users without coupling the product to any one provider.

---

## 1. Why integrate

- **Faster pool discovery surface.** LP Agent exposes a ranked, filterable pool catalogue across Meteora DLMM and DAMM v2, with TVL, volume, fees, bin-step, liquidity, and type filters already computed. This complements our own model-ranked discovery.
- **Portfolio read-through.** `lp-positions/opening` and `lp-positions/historical` endpoints provide rich per-position data (range, in-range status, fees, P&L) that we can surface alongside our internally tracked positions for users who have historic positions opened outside Aura.
- **Zap primitives.** Single-token deposit and withdraw across DLMM positions lower the friction of entering and exiting positions for users holding only one side of a pair.
- **Partner ecosystem.** LP Agent is actively courted by Meteora's partner programme; alignment benefits distribution.

---

## 2. Design stance

1. **Adapter pattern.** A single internal interface — `LpIntelProvider` — defines capabilities we need: `discoverPools`, `getUserPositions`, `zapIn`, `zapOut`. LP Agent is the first implementation. Anything consuming the interface is provider-agnostic.
2. **No leakage.** LP Agent response shapes do not appear in our database rows, UI models, or other services. Everything is translated at the adapter boundary into Aura's canonical domain types.
3. **Graceful degradation.** LP Agent outage must never stop Aura. Each capability has a fallback (§6).
4. **Entitlement aware.** Premium LP Agent endpoints are used only for users on tiers that cover the cost, and only where the added value justifies it.
5. **Audit every call.** Latency, success, rate-limit headers, cost attribution per user. Budget alarms.
6. **Keep the map, drop the guide when needed.** The adapter seam lets us swap or supplement providers without a UX change.

---

## 3. Capabilities we consume (launch scope)

### 3.1 Pool discovery

- Endpoint: `GET /pools/discover` on the LP Agent API.
- Inputs we map: pair search, min TVL, min 24h volume, min 24h fees, bin-step bounds, protocol filter (Meteora DLMM, DAMM v2), sort field (volume, fees, TVL, APR).
- Outputs we surface: pool metadata, protocol, tokens, bin step, TVL, volume24h, fees24h, fee/TVL ratio, active-bin summary.
- Consumption: the Discover tab's "Opportunities" list blends LP-Agent-ranked pools with Aura's model-ranked pools under a single canonical schema.

### 3.2 Open positions (external)

- Endpoint: `GET /lp-positions/opening?owner=<wallet>`.
- Use case: when a user connects a wallet that already has positions opened outside Aura (directly on Meteora or via another tool), we show those positions in the Positions tab, labelled clearly as "External" and non-manageable from inside Aura (read-only until they are closed and re-opened via Aura).
- Data surfaced: range, strategy, current active-bin status, fees claimed, P&L as reported, in-range flag.

### 3.3 Historical positions

- Endpoint: `GET /lp-positions/historical?owner=<wallet>`.
- Use case: "lifetime summary" card for connected wallets.
- Data surfaced: closed positions, total fees earned, total P&L — tagged "External history".

### 3.4 Zap in

- Single-token deposit into a DLMM position. User provides amount in one token; protocol splits into the target range according to the chosen shape.
- Consumption: optional alternative path in the Create flow when the user's holdings are single-sided.

### 3.5 Zap out

- Close a position and settle to a single chosen token.
- Consumption: optional alternative path in the Close flow.

Endpoints flagged as "premium" in the LP Agent tiering (e.g. top-LPer listings per pool) are not part of launch scope but are placeholders in the adapter interface for later.

---

## 4. Adapter interface (logical)

The internal contract is provider-neutral. In plain terms, it exposes:

- `discoverPools(filters, paging) → (pools[], pagingCursor)`
- `getOpenPositions(walletAddress) → positions[]`
- `getClosedPositions(walletAddress, timeRange) → positions[]`
- `buildZapInQuote(pool, range, shape, inputToken, amount) → quote`
- `submitZapIn(quote, signedTx) → executionReceipt`
- `buildZapOutQuote(position, outputToken) → quote`
- `submitZapOut(quote, signedTx) → executionReceipt`

Where a provider returns a transaction envelope to sign client-side (typical Zap pattern), the adapter returns an unsigned-tx descriptor plus the simulation result from the same provider. Aura's execution layer then follows the usual sign-preview and MWA flow (doc 04 §5.2).

Each capability has a `provider` field in telemetry so we can compare providers side by side in the future.

---

## 5. Authentication, rate limits, cost control

- `x-api-key` stored as a backend secret (never shipped to clients). All LP Agent calls route through `bot-control-svc` or a dedicated `lp-intel-svc`.
- Per-user and per-tier rate limits enforced on our side before we call the provider, so heavy users do not burn through shared budget.
- Response headers inspected for provider-side rate-limit signals; backpressure applied when thresholds approached.
- Cost attribution: each provider call tagged with `user_id`, `capability`, and entitlement tier for spend dashboards.
- Cache aggressively: pool discovery results cached 30–60 seconds per filter signature; position reads cached briefly per wallet; zap quotes never cached (always fresh).

---

## 6. Fallbacks and resiliency

- **Pool discovery outage:** degrade to Aura's own model-ranked discovery. UI shows a subtle "extended catalogue temporarily unavailable" hint.
- **External positions read outage:** show cached last-known state with a freshness indicator; block new external-position renders until recovered.
- **Zap outage:** hide Zap CTAs; the classic two-token deposit/withdraw path remains available (built on Meteora SDK directly).
- **Partial outage:** circuit breakers per capability. One failing capability does not take down the others.

The product never depends on LP Agent for a critical path. Critical paths (opening and closing positions against Meteora) continue to work with direct SDK calls even if the adapter is entirely offline.

---

## 7. Data handling

- We translate LP Agent responses into Aura domain types at the adapter boundary.
- We do not persist raw provider payloads in primary tables. Short-lived cache only.
- Wallet addresses passed to LP Agent are the user's connected public keys — public information. We do not send secrets, keys, session tokens, or PII.
- Any field the provider considers confidential by ToS is treated accordingly; we do not redistribute via our public-facing Data API.

---

## 8. Legal, terms, attribution

- Review provider ToS for commercial-use constraints before launch.
- Attribution: where the provider requires or recommends branding on surfaces that use their data, honor it.
- Partner programme enrollment tracked and maintained; credentials treated as secrets.

---

## 9. Monitoring

- Dashboards per capability: QPS, p50/p95/p99 latency, error rate, cost.
- Alerts on sustained error rate > X%, latency regression > Y ms, or cost burn rate outside budget.
- Reconciliation between LP Agent's reported position P&L and Aura's simulator-derived P&L (doc 02) for Aura-opened positions — a useful second opinion; large divergence raises an investigation ticket, not an automatic halt.

---

## 10. Milestones

### L1 — Adapter Skeleton & Secret Onboarding

- Register for API access via the partner portal.
- Store API key; implement `lp-intel-svc` shell with health check.
- Define `LpIntelProvider` interface and Aura canonical domain types.
- **Exit gate:** sandbox calls to `pools/discover` return through the adapter and are translated to canonical types.

### L2 — Discovery Integration

- Wire `discoverPools` into the Discover tab alongside model-ranked pools.
- Caching, rate limiting, cost attribution active.
- Fallback path tested (kill the provider, Discover still works).
- **Exit gate:** a user filter and sort set produces the same result set across two consecutive sessions; cache hit rate ≥ 60% in steady state.

### L3 — Portfolio Read-Through

- `getOpenPositions` and `getClosedPositions` wired into the Positions tab and Account "lifetime" card.
- Clear "External" labelling; no manage actions on external positions.
- Per-user and per-wallet caching.
- **Exit gate:** a tester whose wallet has both Aura-opened and externally opened positions sees a correct, de-duplicated list.

### L4 — Zap In / Zap Out

- Quote + simulate + sign-preview + submit flow for Zap in.
- Same for Zap out.
- Integrated into Create and Close flows as an optional path when the user's holdings justify it.
- Reconciliation with simulator for the expected vs realized outcome.
- **Exit gate:** 25 devnet/mainnet Zap round-trips with sign-preview parity and reconciliation within tolerance.

### L5 — Premium Capabilities (post-launch)

- Top-LPer and other premium endpoints folded into the adapter behind entitlement gates.
- Dashboards comparing premium vs non-premium paths for decision on broad rollout.
- **Exit gate:** premium path gated by entitlement with clean 402 upsell for non-eligible users.

### L6 — Provider Abstraction Hardened

- Second provider prototype implemented behind the same `LpIntelProvider` interface for a subset of capabilities (not necessarily launched), to confirm the abstraction holds.
- Feature flags to route capability-by-capability to a chosen provider per environment.
- **Exit gate:** provider routing changes are config-only, zero code change in consumers.

---

## 11. Bounty / demo deliverable

A dedicated demo flow showcases:

- Pool discovery via LP Agent's catalogue, ranked and filtered.
- External portfolio read-through for a connected wallet.
- Zap in to a discovered pool, then Zap out to the original token.
- End-to-end sign-preview, execution, ledger, and reconciliation.

The demo surface is flag-controlled so it can be featured during the bounty period without being a permanent UI element.

---

## 12. Non-negotiables

- The adapter boundary is inviolable. Provider types never leak into domain code.
- Critical execution paths never depend on the provider being available.
- API keys never ship to clients.
- Every provider call is metered, attributed, and monitored.
- External-position data is labelled as such in every surface it appears; a user never mistakes it for an Aura-managed position.
