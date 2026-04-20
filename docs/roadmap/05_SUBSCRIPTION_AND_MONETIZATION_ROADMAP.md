# 05 — Subscription & Monetization Roadmap

> The subscription system is wired end-to-end from day one. Charging is toggled by a billing-mode flag. When the flag flips from `trial` to `live`, nothing in code changes — only the provider starts charging. This lets us validate the full enforcement path in production before taking a single dollar.

---

## 1. Principles

1. **Entitlements over role strings.** Code checks entitlements (fine-grained capabilities), not tier names. "Can run N automated bots" is an entitlement; "Pro" is a bundle of entitlements.
2. **Server-authoritative.** Every gated action is enforced at the backend (§7), not just hidden in the UI. The UI is a hint, not a gate.
3. **Billing provider owns money, we own policy.** Provider (e.g. Stripe / RevenueCat) handles payments, tax, dunning. We translate their state into our entitlement state.
4. **Idempotent everywhere.** Webhooks can arrive multiple times, out of order. Our ledger of subscription events is immutable and replayable.
5. **Graceful degradation.** Expired subscriptions stop gaining the user new benefits but do not strand user funds. Positions are never force-closed for non-payment.
6. **No dark patterns.** Cancel is one tap. Downgrade takes effect at period end, with clear date. Refund policy published.
7. **Regional pricing rational.** Single base price at launch; localized later through the provider's native mechanisms.
8. **Trial without friction.** New users can taste paid features without a card. When charging goes live, a one-tap upgrade completes the loop.
9. **Performance fees are separate from subscriptions.** Subscription unlocks capability. Performance fee is a usage cost on Delegate profits only.
10. **Every price change is reversible.** Grandfathering rules explicit. Historical pricing preserved per user.

---

## 2. Tier structure (launch intent)

### 2.1 Free
- Execute mode unlocked (user signs every action).
- **Paper mode unlocked** without limits — this is the product's honest shop window.
- One (1) live automated bot with a small notional cap (e.g. $200) to let users feel Automate.
- Full access to market data on the current day.
- Basic notifications.

### 2.2 Pro — $9.99 / month
- Unlimited automated bots (subject to per-user fleet caps for fairness).
- Higher notional caps (user-configured within platform bounds).
- Delegate mode eligibility (with step-up auth).
- Priority execution queue.
- Historical analytics beyond current day.
- Advanced notifications (risk alerts, reconciliation warnings).
- Priority support.

### 2.3 Data API (separate product, out of the subscription flow at launch)
- Tiered API access to the model's predictions and the simulator's reports for third parties. Scaffolded in the architecture but not launched in phase one.

### 2.4 Performance fee (Delegate only)
- 10% of realized profit on Delegate-mode positions, measured against a high-water mark.
- Deducted on position close or on monthly reconciliation, whichever comes first.
- Transparent calculation shown in the monthly statement.
- Never applied to Execute or Automate; never applied to unrealized gains; never applied to paper.

---

## 3. Entitlement catalogue (examples)

| Key | Meaning |
|-----|---------|
| `paper.enabled` | May open and run paper positions |
| `execute.enabled` | May open live positions via Execute mode |
| `automate.bots.max` | Integer cap on active automated bots |
| `automate.notional.max` | USD cap on automated notional per bot |
| `delegate.enabled` | May enter Delegate mode (gated also by step-up) |
| `analytics.history.days` | How far back analytics is visible |
| `notifications.advanced` | Access to risk/reconciliation alerts |
| `support.priority` | Priority support queue |
| `api.access` | Data API access (future) |
| `api.rate.rps` | Rate cap for API callers |

A tier is a JSON document mapping keys to values. Adding a capability is a catalogue edit; no code change in consumers that already check the relevant key.

---

## 4. Data model

- `subscriptions` — one row per user per active subscription. Fields include tier, status (`trialing`, `active`, `grace`, `past_due`, `canceled`, `paused`), current_period_start/end, provider ids, raw provider snapshot.
- `subscription_events` — append-only log of all state transitions (self-initiated, webhook-driven, admin-override). Each with correlation id and actor.
- `entitlements_cache` — denormalized per user, recomputed on every subscription event. Consumers read this cache only.
- `performance_fee_ledger` — per Delegate-position fee accruals, debits, high-water-mark snapshots, payout records.

No field is mutable without producing a `subscription_events` row.

---

## 5. Billing modes (the switch)

The `billing-svc` runs in one of three modes, globally flagged:

- **`off`** — everyone has the maximum entitlement bundle; no provider calls. Used in early dev.
- **`trial`** — all infrastructure operational: provider sandbox, webhooks, entitlement updates, upgrade/downgrade UI. No real charges. Users who "upgrade" are flipped into a trial subscription that never bills.
- **`live`** — provider moves to production keys; real charges. No code change beyond the flag flip; all flows already exercised in `trial`.

The transition from `trial` to `live` is a release gate with a dry-run in stage against the provider's live endpoints using an isolated test account.

---

## 6. Provider integration

- Provider choice prioritizes: mobile SDK maturity (for in-app purchase parity with store policies), webhook reliability, strong tax/VAT handling, good dunning UX.
- Webhook endpoint verifies signatures, enqueues event for idempotent processing, returns 2xx fast.
- Out-of-order / duplicate events: resolver uses provider event id as idempotency key; stale events (older than cached snapshot) ignored with audit log entry.
- Reconciliation job: nightly pull of the provider's subscription roster compared to our cache; divergence triggers an incident.
- Refunds and chargebacks propagate to entitlements automatically (grace first if mid-period, immediate revoke if fraud flag).

---

## 7. Enforcement

Entitlement checks happen at the backend, at the edge of each entitled action:

- `edge-gateway` middleware rejects requests to paid endpoints with `402 payment_required` if the caller lacks the entitlement, returning a machine-readable upsell payload the app can render.
- `bot-control-svc` checks `automate.bots.max` on start; rejects with a typed error if exceeded.
- `execution-svc` checks `automate.notional.max` against the position's notional at intent creation.
- `ml-inference-svc` enforces `api.rate.rps` on external API callers.
- Delegate gating requires both `delegate.enabled` and a recent step-up auth artefact.

The UI reads the same entitlement cache and hides/disables features, but the truth is always the backend check. A user who bypasses the UI hits a server-side wall.

---

## 8. Lifecycle states

### 8.1 Trialing → Active
User subscribes; provider returns active status; entitlements upgraded; user notified.

### 8.2 Active → Past due
Provider charge fails. User enters `grace` for a configured window (default 7 days). Entitlements remain active. UI shows a persistent banner with one-tap update-payment. After grace, entitlements revert to Free; automated bots exceeding free caps are paused (not force-closed) and displayed as "paused — subscription lapsed".

### 8.3 Active → Canceled (user-initiated)
Cancel takes effect at period end. Entitlements remain active until period end. At period end, downgrade to Free with the same pause-not-close rule.

### 8.4 Paused (user-initiated, provider-supported)
Subscription pause for a configurable window; treated like canceled for entitlement purposes during the pause; resumes with original renewal cadence.

### 8.5 Refund / chargeback
Entitlements revert based on policy (§9). Audit trail preserved. If fraud-flagged, account moves into a manual-review state.

### 8.6 Reactivation
User re-subscribes; entitlements restored; previously paused bots remain paused pending explicit user action (safety default).

---

## 9. Refund, dispute, and fairness policy

- **14-day good-faith refund** for first-time subscribers on written request.
- **Pro-rated refunds** on annual plans when launched.
- **Automatic refund** on provider-level duplicate charge.
- **No refund** for performance fees on realized profit — performance fees only fire on profit.
- Disputes: paused account pending resolution; user notified; positions untouched.

---

## 10. Performance fee mechanics (Delegate)

- Measured per user, per strategy family, with a high-water mark (HWM) in USD.
- Fee = max(0, current_equity − HWM) × 10%, realized on close or monthly.
- Calculation uses the simulator's ledger (doc 02) as the P&L source of truth — no alternative accounting.
- Debits from a dedicated fee-escrow account; user-visible ledger shows accrual and debit separately.
- Clawback-free: fees paid are never reversed; subsequent drawdowns simply lift the HWM forward only after recovery.
- Monthly statement: HWM, starting equity, ending equity, realized profit, fees accrued, fees debited.

---

## 11. UI surfaces (pointers to doc 04)

- Account tier card with clear renewal date, tier benefits, and one-tap upgrade/downgrade/cancel.
- Upgrade modal triggered on server-returned `402` payloads with reason and CTA.
- Usage meters for metered entitlements (bots active of max, notional used of cap).
- Delegate-specific: risk profile, HWM, fee accrual, monthly statement export.
- Billing event banners (grace, canceled-pending, paused).

---

## 12. Compliance, tax, platform rules

- Sales tax and VAT handled by the provider; we consume the final computed amounts.
- App-store platform rules: when distributing via Play Store / App Store, use the platform's in-app purchase for digital subscription where required. Web/direct billing paths where permitted. Provider abstracted enough to support both.
- Receipts issued by the provider; mirrored in-app for user convenience.
- Dunning communication respects the user's notification prefs plus a single non-optional "payment required" channel.

---

## 13. Fraud and abuse

- One active paid subscription per wallet address; additional subs flagged for review.
- Device fingerprint + wallet fingerprint for chargeback-rings detection.
- Stolen-card signals from the provider auto-trigger revoke + review.
- Refund abuse (serial refunders) tracked; policy enforcement per §9.

---

## 14. Experiments and pricing evolution

- Price changes applied forward only; existing subs grandfathered until explicit renewal under new terms or opt-in switch.
- A/B tests on landing-page copy only, not on active-user pricing.
- Feature-flagged experiments on entitlement bundles for new users; always reversible.
- Every experiment has a defined duration and a decision doc at end.

---

## 15. Milestones

### M1 — Catalog & Cache
- Entitlement catalogue schema defined and seeded with launch tiers.
- Entitlements cache service + read API.
- Backend enforcement middleware in place for all paid endpoints.
- **Exit gate:** a dummy user can be toggled across tiers by admin and every gated endpoint behaves correctly.

### M2 — Provider Integration (Trial Mode)
- Webhook endpoint with signature verification, idempotent processing.
- Subscription event log + reconciliation job.
- In-app upgrade/downgrade/cancel flows against provider sandbox.
- Grace and pause states fully wired.
- **Exit gate:** 30-day trial-mode run in stage with synthetic users exercising every state transition without a single entitlement desync.

### M3 — UI & Communication
- Account tier surfaces, upgrade modals from 402 responses, usage meters.
- Billing event banners, dunning notifications, receipt mirror.
- Support-side tools for viewing subscription event history.
- **Exit gate:** a support engineer can answer any "why was I charged / why can't I do X" question in under a minute from the console.

### M4 — Performance Fee (Delegate prerequisite)
- HWM tracking, accrual, debit pipeline against the simulator ledger.
- Fee-escrow account and reconciliation.
- Monthly statement generation + export.
- **Exit gate:** a multi-month synthetic Delegate user has HWM, accrual, and debit records that reconcile to the simulator ledger to the cent.

### M5 — Go Live
- Dry-run against provider production account with controlled user set.
- Regulatory / tax / receipt review closed.
- Rollback plan rehearsed.
- Flip `trial` → `live`.
- **Exit gate:** 72 hours in `live` with zero webhook failures, zero reconciliation divergences, zero erroneous 402s for paying users.

### M6 — Pricing Evolution
- Regional pricing enabled via provider localization.
- Annual plan option.
- Data API tiering launched as a separate product surface.
- **Exit gate:** pricing changes applied without regressing any grandfathered user.

---

## 16. Non-negotiables

- Enforcement is server-side. Always.
- Subscription lapse never causes a forced close of a user position.
- Every charge has an audit trail across our system and the provider's.
- Cancel is never more than one tap.
- Performance fees are never charged on unrealized gains or on paper trades.
- We never bill in `off` or `trial` mode. The switch to `live` is ceremonial and auditable.
