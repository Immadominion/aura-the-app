# 04 — Mobile UI Roadmap (Flutter / Android)

> Aura's product surface is a mobile app. Execution happens where the user already is. This document sequences the UI capabilities to match the platform's growing trustworthiness — paper first, live next, delegate last — and specifies the user experience rules that keep an autonomous money-moving app safe.

---

## 1. Product pillars (UI rules of the road)

1. **Never lie about reality.** If we are in paper mode, say so, loudly, on every screen that shows P&L. If a price is stale, mark it stale. If a position is out of range, show it.
2. **One tap to stop.** Global kill switch reachable from anywhere in ≤ 2 taps. Never buried.
3. **Signatures are sacred.** Any on-chain action shows the exact effect in plain language before MWA is invoked. No surprise signing.
4. **Progressive disclosure.** A first-time user sees 3 controls. A power user can unfold the engine room. Same screens, same vocabulary.
5. **Deterministic UX.** The same inputs produce the same outputs visually. No randomized layouts, no ambiguous states.
6. **Offline-tolerant.** The app renders last-known state when offline and clearly marks freshness.
7. **Accessibility first.** WCAG AA contrast, semantic labels on every interactive element, dynamic type, screen-reader narration for every live update.
8. **Localized for growth.** All strings externalized. Numbers, dates, currencies formatted by locale.
9. **Animations serve information.** No motion for decoration. Reduce-motion honoured.
10. **Privacy by default.** No PII collected unless strictly needed. Biometric lock opt-in for the app itself on day one.

---

## 2. Three-mode mental model (from business spec)

The app's primary navigation expresses the three execution modes:

- **Execute** — user tells the app to open a position; the app builds the transaction, user signs, position opens. Classic wallet action.
- **Automate** — user configures a bot with rules and limits; app signs with the *per-bot* keypair within the limits, user can pause anytime. Non-custodial of primary wallet, custodial of bot keypair (encrypted in vault).
- **Delegate** — managed strategies; the platform selects and rebalances inside a risk profile. Requires step-up auth. Performance-fee-bearing.

Each mode has a distinct visual treatment (not colour-coded alone — also iconography and microcopy) so a user always knows which mode they are operating in.

---

## 3. Information architecture

Top-level tabs:

1. **Home** — portfolio summary, active bots, alerts, market snapshot.
2. **Discover** — curated pools, model-ranked opportunities, search/filter.
3. **Positions** — open, paper, closed; filters by mode, status, pool.
4. **Create** — guided flow to open a new position or configure a bot.
5. **Account** — subscription, wallet, security, settings.

Persistent UI elements:
- **Status bar:** paper/live badge, oracle freshness indicator, global kill-switch shortcut.
- **Alert tray:** accessible from any screen; shows recent bot decisions, reconciliation warnings, system notices.

---

## 4. Core screens and their rules

### 4.1 Home
- Hero card: total portfolio value, 24h change, mode badge (Paper / Live / Mixed).
- Active bots list with per-bot mini-sparkline and status (running, paused, out-of-range, stuck).
- Recent decisions feed: "Bot X opened position in pool Y. Expected net 24h: +$Z. Rationale: ⋯". Every row links to the decision record.
- Market snapshot: a small set of pool cards surfaced by the model with a clear "predicted 24h net" and a "why" tap.

### 4.2 Position detail
- Summary: entry time, range, strategy shape, current active-bin position relative to range (visual).
- Live P&L card: realized fees (net of protocol fee), IL, costs, net. Every number has a tap-through to its derivation.
- Event timeline: swaps affecting the bin, rebalances, claims, chunked closes.
- Simulator overlay: predicted vs realized curve when live shadow is active.
- Actions (mode-dependent): close, rebalance, pause-bot, adjust-range.
- Reconciliation badge: green (within tolerance), amber (drift observed), red (direction flip). Red opens an incident detail.

### 4.3 Create flow
Step-by-step, with simulation preview at every step:
1. Pick pool (search, filters, model-ranked list).
2. Choose mode (Execute / Automate / Delegate).
3. Configure range, shape, amount. Live simulation card updates in real time showing expected net P&L over a user-selected horizon with an uncertainty band.
4. Configure limits (max loss, max position size, kill conditions).
5. Review screen shows the exact transaction and effect; user taps to sign via MWA. For Automate, user also authorizes the bot's signing authority scope.
6. Confirmation shows the position entry ledger.

### 4.4 Bot detail
- Rules: current config, editable.
- Guardrails: max-loss, max-notional, allowed pools. Changing these is a signed action.
- Decision log: full audit trail of the bot's recent reasoning.
- Pause / stop controls with confirm-by-biometric.
- Vault status: key health, last-rotation date (for the bot key).

### 4.5 Paper mode ubiquity
Paper positions appear in the same lists as live positions, distinguished by a persistent "Paper" badge on every card and every detail screen. P&L columns visibly segregate paper vs live totals. There is never a state where a user could confuse a paper number for a live number.

### 4.6 Account
- Subscription tier card (doc 05) with next renewal, usage meters for metered features.
- Wallet section: connected wallet address (truncated), bot keypair vault status, per-bot key ages.
- Security: biometric lock toggle, session devices list, sign-out-everywhere, passkey enrolment for Delegate.
- Data: export my data, delete my data.

---

## 5. Trust and safety UI

### 5.1 Kill switches
- Global "Stop everything" button in the status bar. Double confirmation + biometric.
- Per-bot stop on the bot detail screen. Single confirmation.
- System-initiated pause banner: when the platform auto-pauses (ML offline, oracle stale, reconciliation drift) the user sees a persistent banner explaining why and when automation will resume.

### 5.2 Signing prompts
- Every MWA signature request is preceded by an in-app preview that shows:
  - Action in plain English ("Open $250 position in SOL/USDC, range X–Y, Spot shape").
  - Expected outcome (predicted net P&L from simulation).
  - Worst-case loss within the configured limits.
  - Costs (priority fee, rent, protocol fee share).
  - Programs that will be invoked.
- A mismatch between previewed action and the signed transaction triggers a client-side abort.

### 5.3 Freshness indicators
- Every price shows its age in a subtle inline label ("9s"), turning amber at configurable thresholds.
- Pool state timestamps shown on position cards when > 15s stale.
- Model inference timestamp shown on decision cards; > 60s stale triggers a "refresh" prompt, blocks new actions.

### 5.4 Drift and reconciliation surfaces
- Per-position reconciliation badge (§4.2).
- Account-level health card: percentage of positions reconciling within tolerance, trended over 30 days.
- If platform-wide drift triggers a promotion halt, user-visible banner: "Automation is temporarily conservative while we verify a model update."

---

## 6. Mode-specific UX contracts

### 6.1 Execute
- No bot keypair involved. User signs every action with the primary wallet via MWA.
- Simpler create flow (steps 1, 3, 5 from §4.3).
- No subscription required for basic Execute (see doc 05 free tier).

### 6.2 Automate
- Bot keypair generated on first automation; user signs a delegation authorizing its scope.
- Scope is explicit: pool allowlist, notional cap, time horizon, allowed action types.
- Any change to scope is a signed action with a visible diff.
- Emergency revoke: one-tap revocation of the bot's signing authority; all downstream actions refused.

### 6.3 Delegate
- Requires Pro subscription + step-up auth (passkey or signed challenge).
- Risk profile selector: conservative / balanced / aggressive — each mapped to concrete bounds (max drawdown, max concentration).
- Performance fee disclosed on entry, calculated on close against high-water mark.
- Monthly statement in-app and exportable.

---

## 7. Onboarding

- First launch: 3-screen intro (self-directed tooling, non-custodial, paper-first).
- Wallet connect via MWA with clear explanation of what the app will ask to sign and what it will not.
- Free tier defaults: paper mode unlocked, one automated bot with a small notional cap (see doc 05).
- "Try it on paper" CTA as the default primary action for any opportunity until the user has completed their first live execution.

---

## 8. Notifications

- Opt-in on first bot creation; explain categories.
- Categories: bot events (opened/closed/paused), risk alerts (out-of-range, drift), subscription (renewal, dunning), product (releases, updates).
- Rate-limited per category; digestable (daily digest option).
- Every notification deep-links to the relevant screen with the relevant state loaded.

---

## 9. Performance and quality targets

- Cold start to Home with last-known data < 2s on mid-range Android.
- Sub-16ms frame times on the three hot lists (Home, Positions, Discover).
- Live update for a position's P&L card < 500ms from pool-state change to visible update.
- Crash-free sessions ≥ 99.7%.
- ANR-free sessions ≥ 99.9%.

---

## 10. Accessibility and inclusivity

- Full screen-reader coverage; every live number has a spoken description.
- Dynamic type up to 200% without layout breakage.
- Colour not load-bearing; every state has text + icon.
- Haptics for confirmatory actions but never as the only signal.
- RTL layout support wired from day one.

---

## 11. Telemetry and feedback

- Anonymous product telemetry opt-in; clear disclosure.
- In-app feedback form on every screen (long-press the header).
- Bug report bundles anonymized logs and last-seen state (user can preview before sending).

---

## 12. Design system

- Single token source (colours, spacing, type, elevation) consumed by Flutter theme and design files alike.
- Dark mode first; light mode achieves contrast parity.
- Reusable primitives: `StatCard`, `RangeIndicator`, `BinVisualizer`, `PaperBadge`, `FreshnessLabel`, `SignPreview`, `KillSwitch`, `ReconciliationDot`.
- Motion tokens: `quick (120ms)`, `standard (240ms)`, `emphatic (360ms)` — no bespoke timings.

---

## 13. Platform strategy

- Android first (Flutter). iOS later; architected not to block on platform channels Android-only.
- MWA deep links handled with fallback UX for users without a compatible wallet.
- Background work: no silent execution in v1. All automated actions happen on the backend; the app only observes and controls.
- Deep linking: every screen addressable by URL for support reference and notification hand-off.

---

## 14. Milestones

### U1 — Foundations
- Design system, navigation skeleton, auth flow, MWA wiring.
- Home with static data, Account, Settings.
- Biometric app lock, dark mode, accessibility pass 1.
- **Exit gate:** first-launch-to-connected-wallet in under 60 seconds.

### U2 — Paper Mode Complete
- Discover with model-ranked pools (doc 01) over paper.
- Create flow with live simulation preview (doc 02).
- Paper positions list, position detail with full ledger and timeline.
- Status bar freshness indicators.
- **Exit gate:** a user can open a paper position, monitor it end-to-end, and close it, with numbers reconciling to backend ledger to the cent.

### U3 — Live Execute
- MWA sign preview with action + worst-case + costs.
- Live position opening flow.
- Live vs paper segregation across all lists.
- Global kill switch reachable anywhere.
- **Exit gate:** 50 successful devnet/live round-trips with no sign-preview mismatches; every abort path exercised.

### U4 — Automate
- Bot create flow with scope authorization.
- Bot detail with decision log, guardrails, pause/stop, revoke.
- Notifications category: bot events.
- **Exit gate:** a Pro tester runs an automated bot for 7 days with audit-trail completeness verified against the backend.

### U5 — Subscription & Entitlements UI
- Tier selector (doc 05), upgrade flow, usage meters.
- Entitlement-gated surfaces clearly signposted with upgrade CTAs.
- Billing states (active, grace, delinquent) reflected in UI.
- **Exit gate:** upgrade / downgrade / cancel flows each tested end-to-end including edge cases (card decline, refund).

### U6 — Delegate
- Risk profile selector, step-up auth, high-water-mark fee disclosure.
- Monthly statement view.
- Performance dashboard comparing Delegate to Automate and to passive hold.
- **Exit gate:** Delegate closed-beta with < N users, zero custodial-feeling incidents, audit of signing surface.

### U7 — Polish & Scale
- iOS parity.
- Localization for N languages.
- Reduced-motion and full a11y audit closed.
- Performance budget enforced in CI.
- **Exit gate:** app-store review completed in both stores; crash-free ≥ 99.7% over 30 days post-launch.

---

## 15. Explicitly deferred

- In-app swapping beyond what's needed to fund LP positions.
- Social features (sharing, leaderboards).
- CEX integrations.
- Fiat on/off ramps (handled externally via partner links when relevant).
- Desktop/web client (web landing page only — see `aura-landing/`).

---

## 16. Non-negotiables

- Paper and live totals never mix silently.
- Every signature has a preview.
- Every automation has a scope and a revoke.
- Every drift has a surface.
- Every loss has an explanation.
- The app never moves money without the user's explicit grant and never beyond the scope of that grant.
