# 03 — Backend Infrastructure Roadmap

> Aura's platform is production-grade from day one. The model is the MVP — the infrastructure that carries user capital is not. This document specifies the target architecture, the security posture, the operational posture, and the rollout order.

---

## 1. Design principles

1. **Non-custodial by default.** User funds live in per-bot keypairs the user authorizes via MWA. Servers never see a user's primary wallet key.
2. **Least privilege everywhere.** Every service has its own IAM role, its own secrets, its own database credentials. A compromise of one service must not compromise another.
3. **Everything is idempotent.** Every state-changing call has an idempotency key. Network retries never double-act.
4. **Every external call is observable.** RPC, oracle, Jupiter, Meteora SDK — all wrapped, metered, timed, logged with correlation IDs.
5. **Kill switches at every layer.** Global, per-service, per-pool, per-bot, per-user. Any engineer on-call can stop execution in under 30 seconds.
6. **No shared mutable state across tenants.** Bots cannot read each other. Users cannot read each other. Enforced at the database row level and at the API boundary.
7. **Fail closed.** Ambiguous auth, expired subscription, missing feature flag, degraded dependency → deny, not allow.
8. **Reproducible deploys.** Infra is code. Every environment is standup-able from Git + a secrets bootstrap.
9. **Data sovereignty.** User PII and wallet mappings are encrypted at rest with a key the application does not hold in memory longer than needed.
10. **Security is a release gate, not a backlog item.** See §11.

---

## 2. Service boundaries (logical)

The backend decomposes into focused services. Each owns its data, exposes an internal API, and is independently deployable.

| Service | Responsibility | Reads | Writes |
|---------|----------------|-------|--------|
| `edge-gateway` | TLS termination, WAF, rate limit, auth verification, request routing | — | access log |
| `auth-svc` | Wallet-based sign-in (SIWS), session issuance, device binding, MFA for Delegate | sessions | sessions |
| `user-svc` | User profile, entitlements cache, device list, notification prefs | users | users |
| `bot-control-svc` | Bot lifecycle: create, start, pause, stop, rebalance directive | bots, positions | bots, position intents |
| `market-data-svc` | Pool state polling, oracle ingest, event fan-out | Meteora SDK, Pyth, Jupiter | pool_state, oracle_ticks |
| `ml-inference-svc` | Scoring bots with loaded model, producing decision records | features, models | predictions |
| `simulation-svc` | Paper mode, shadow runs, backtests (doc 02) | events, prices | ledgers, reconciliations |
| `execution-svc` | Builds, signs (per-bot keypair), submits, confirms transactions | intents, keypairs | on-chain txs, tx_log |
| `wallet-vault-svc` | Encrypted per-bot keypair storage; never returns plaintext to other services, only signs | KMS, vault db | vault db |
| `ledger-svc` | Per-position P&L ledger, fee/cost accounting, reconciliation with on-chain | tx_log, ledgers | ledgers |
| `billing-svc` | Subscription state, entitlements, invoice generation, webhook processing | billing provider | subscriptions |
| `notification-svc` | Push, email, in-app banners; templated and rate-limited | users, events | delivery log |
| `admin-svc` | Operator dashboard APIs, kill switches, feature flags, incident tools | all (read) | flags, incidents |

Inter-service comms: internal mTLS on a private VPC network. No service is internet-reachable except `edge-gateway`.

---

## 3. Data stores

### 3.1 Primary OLTP — Postgres (managed, multi-AZ)
- Per-service schemas with row-level security on user_id / bot_id.
- Read replicas for analytics and admin read paths.
- Point-in-time recovery, 30-day retention. Daily logical backups to cold storage.
- Connection via service-specific credentials rotated automatically.

### 3.2 Time-series — market data
- Pool state snapshots, oracle ticks, swap events: partitioned by time, hot window in Postgres (7d) or a purpose-built TSDB, cold window in parquet on object storage.

### 3.3 Analytics / ML feature store — S3 + parquet
- Continuation of the Old Faithful pipeline. Canonical location for training data and simulator inputs.
- Immutable by convention: epochs are append-only.

### 3.4 Model artefacts — versioned object storage
- `s3://aura-models/<family>/<semver>/…` (see doc 01).
- Immutable. Served via signed URLs to `ml-inference-svc` only.

### 3.5 Secrets — managed secrets service (AWS Secrets Manager or equivalent)
- No secret on disk, no secret in environment of a long-lived process beyond boot fetch.
- Per-service access policies.

### 3.6 Wallet vault
- Separate physical database, separate VPC subnet, separate IAM role.
- Keypairs encrypted with AES-256-GCM.
- **Data encryption key (DEK)** per bot, wrapped by a **key encryption key (KEK)** stored in KMS.
- Only `wallet-vault-svc` holds the IAM permission to call `kms:Decrypt` on the KEK.
- Other services request a *signature*, never a key. The vault signs inside its process boundary.

---

## 4. Request lifecycle (illustrative: "start bot")

1. Mobile client sends POST `/bots/{id}/start` with a short-lived session token.
2. `edge-gateway` validates the token, applies WAF rules, rate-limits per user, injects a correlation ID.
3. `auth-svc` (via gateway middleware) verifies the session is bound to the device.
4. `bot-control-svc` loads the bot, confirms ownership, checks entitlement with `billing-svc` (cached), verifies global + pool + user kill switches via `admin-svc`.
5. A position *intent* is emitted to `execution-svc`.
6. `execution-svc` pulls the latest pool state from `market-data-svc`, asks `ml-inference-svc` for a decision, asks `simulation-svc` for a pre-trade predicted P&L and confirms it passes the bot's risk gates.
7. `execution-svc` constructs the transaction, requests a signature from `wallet-vault-svc`, submits to an RPC, waits for confirmation.
8. `ledger-svc` records the result; `simulation-svc` opens a shadow simulation; `notification-svc` optionally pings the user.
9. Every hop logs with the same correlation ID. Every hop has a latency histogram. Every failure has a typed error.

Idempotency: the intent carries a client-supplied idempotency key; retries at any layer resolve to the same intent.

---

## 5. Runtime / hosting

- **Cloud:** AWS (primary). Multi-region-capable, launch in a single region with DR plan for a second.
- **Orchestration:** managed Kubernetes (EKS) with autoscaling per service. Stateful services (vault, db) on managed RDS/KMS.
- **Networking:** VPC with private subnets for all services; only the gateway's ALB is public. Security groups default-deny.
- **Edge:** CloudFront + AWS WAF with managed rule sets (OWASP core, bot control) plus custom rules (path allowlist, geo fences for restricted jurisdictions).
- **DNS:** Route53 with health-checked records; automated failover to a static maintenance page on full-outage scenarios.
- **Certs:** ACM-issued, auto-rotated.

---

## 6. Observability

- **Metrics:** Prometheus-compatible per service. Gold-signal dashboards (RED/USE) per service. Business dashboards (bots active, PnL/hour, predictions/hour, rejections/hour).
- **Logs:** structured JSON, shipped to a central log store with per-team retention; PII redacted at source.
- **Traces:** OpenTelemetry across every internal hop and every external call. Correlation ID propagated end-to-end through the mobile client.
- **Synthetic probes:** every critical path (login, start bot, fetch position, paper-run tick) probed from an external location every minute.
- **SLOs:**
  - API availability 99.9% monthly.
  - Execution end-to-end latency (intent → signed tx submitted) p99 < 3s under normal pool load.
  - Paper-mode tick freshness p99 < 15s.
  - No missed oracle tick > 30s without alert.

---

## 7. Resilience

- **Retries:** every external call has an explicit retry policy with capped backoff and a circuit breaker. RPC providers fronted by a multi-provider pool with automatic failover (primary / secondary / tertiary) and per-provider health.
- **Queues:** execution intents flow through a durable queue so a restart never drops work. Idempotency keys ensure replay safety.
- **Backpressure:** a slow RPC degrades one bot's execution, not the whole fleet; per-bot work has per-bot concurrency caps.
- **Degraded modes:**
  - If `ml-inference-svc` is down → auto-pause all automated bots that require a fresh prediction, surface a banner.
  - If `market-data-svc` is stale → reject new entries, hold existing positions.
  - If `wallet-vault-svc` is unreachable → read-only mode, no signing.
- **Chaos drills:** quarterly game-day exercising each degraded mode.

---

## 8. Security posture

### 8.1 Identity
- User sessions: sign-in-with-Solana (SIWS) issuing short-lived JWTs (≤ 15 min) + refresh tokens bound to the device.
- Delegate-mode promotion requires a step-up: wallet signature on a time-boxed challenge + optional passkey MFA.
- Admin access to production: SSO + hardware MFA. No standing admin credentials; just-in-time elevation with audit trail.

### 8.2 Secrets
- Service secrets injected at boot from Secrets Manager via IAM role.
- User API keys (data tier) hashed at rest with a pepper; shown once at creation.
- No secret ever in a log, a trace, or an error message. Static-analysis rules in CI to catch regressions.

### 8.3 Wallet vault (expanded)
- DEK per bot, 256-bit, unique. Wrapped by KEK in KMS.
- Sign operations performed in-process; plaintext key never crosses the service boundary.
- Rotate KEK annually; DEK rewrap on rotation (no downtime — dual-unwrap window).
- Sign operations rate-limited per bot and per user; anomalous spikes alert.
- Every signature is logged (bot id, tx hash, program id, instruction set summary); logs are append-only in a tamper-evident store.

### 8.4 Data protection
- TLS 1.3 everywhere, internal mTLS.
- At rest: database and S3 encrypted with KMS-managed keys.
- PII minimization: we store wallet addresses and opt-in contact info. We do not store names, government IDs, or geolocation unless required for compliance.
- Per-user "delete my data" path wired from day one (regardless of legal requirement).

### 8.5 Input handling
- Strict schema validation at the gateway (reject-by-default). Max body sizes per endpoint.
- SQL via parameterised queries only; lint rule to forbid string concatenation in query builders.
- Output encoding on anything rendered; no user string ever templated into a shell command.
- File uploads: none in v1. Any future upload is virus-scanned and stored in an isolated bucket.

### 8.6 Supply chain
- Dependency pinning; weekly vulnerability scan; SBOM generated per release.
- Signed container images; admission controller enforces signature verification in production.
- No `curl | bash` in build scripts. No fetch-at-runtime from untrusted sources.

### 8.7 OWASP Top 10 mapping
For each category (Broken Access Control, Cryptographic Failures, Injection, Insecure Design, Security Misconfiguration, Vulnerable Components, Identification & Authentication Failures, Software & Data Integrity Failures, Security Logging & Monitoring Failures, SSRF) the release checklist requires a named owner, a concrete mitigation, and a test.

### 8.8 Abuse and fraud
- Per-user and per-IP rate limits at the edge.
- Fingerprinting for bot signup to reject mass registration.
- Sanctions screening on withdrawal addresses (if/when the product lists such a feature).

---

## 9. Compliance posture

- Product positioning is tooling for self-directed users, not managed asset management. Legal review at every tier boundary before launch.
- Terms of service + privacy policy published and versioned.
- Geo gating at the edge for jurisdictions requiring specific licensing we do not hold.
- Audit trail retention ≥ 1 year for financial events (execution, billing).

---

## 10. Environments and deploys

- **Environments:** `local` (docker-compose), `dev` (shared), `stage` (prod parity, synthetic traffic), `prod`.
- **Branching:** trunk-based with short-lived feature branches. Main is always releasable.
- **CI:** unit → integration → contract → security (SAST, dependency, secret scan) → simulator CI (doc 02) → deploy to dev → smoke → promote.
- **Deploys:** blue/green per service. Canary for gateway and execution. Auto-rollback on SLO burn.
- **Migrations:** expand/contract pattern; never drop a column in the same release that stops writing it.
- **Secrets changes:** out-of-band, with dual approval.

---

## 11. Release gates

No change reaches production without all of:
1. Tests green (unit, integration, contract).
2. Security scans clean (no high/critical findings; mediums with accepted-risk justification).
3. Simulator CI green (doc 02) if the change touches execution, accounting, or models.
4. Migration dry-run on stage.
5. Observability: new code paths have metrics and traces; new errors have typed codes and runbook entries.
6. On-call sign-off for the affected service.
7. Change record (title, blast radius, rollback plan) filed.

---

## 12. Operational tooling

- **Admin console** (`admin-svc`): read-only views of user accounts, positions, recent executions; search by user, bot, tx; ability to trigger kill switches; never exposes raw keys.
- **Runbooks** per alert: link to dashboard, likely causes, mitigation steps, escalation path.
- **On-call rotation** with a single responder and a shadow. Follow-the-sun when team size allows.
- **Incident process:** severity matrix, comms templates, post-mortem within 5 business days, action items tracked to closure.
- **Feature flags:** every risky change behind a flag; flags auditable and time-boxed (stale flag → cleanup ticket auto-filed).

---

## 13. Performance and scale targets

- 10k concurrent bots at GA; architecture scales horizontally per service.
- 100k predictions/day at GA; cached per pool where inputs are unchanged.
- Edge throughput ≥ 1k req/s sustained per region with burst to 5k.
- Cost envelopes per service monitored; no unbounded pagination, no n+1 RPC calls.

---

## 14. Milestones

### B1 — Foundations
- VPC, managed Postgres, KMS, Secrets Manager, EKS, base CI/CD.
- `edge-gateway`, `auth-svc`, `user-svc`, `admin-svc` online with kill switches.
- Observability stack (metrics, logs, traces) end-to-end.
- **Exit gate:** a login flow is traceable end-to-end; a kill switch stops a dummy operation in < 30s.

### B2 — Wallet Vault & Execution Spine
- `wallet-vault-svc` with KMS-backed key hierarchy, rate limits, anomaly detection.
- `execution-svc` with idempotent intents, multi-RPC failover, structured tx logs.
- `ledger-svc` tied to `execution-svc` events.
- **Exit gate:** a signed devnet transaction round-trips through the full pipeline with complete ledger and audit trail. Vault passes a red-team exercise focused on key exfiltration.

### B3 — Market Data, ML, Simulation
- `market-data-svc` with oracle + pool-state feeds.
- `ml-inference-svc` serving the doc 01 model registry.
- `simulation-svc` implementing doc 02 paper + shadow modes.
- **Exit gate:** paper mode runs for 7 days without dropped ticks; shadow simulation reconciles against a live test position within tolerance.

### B4 — Billing & Entitlements
- `billing-svc` wired to provider webhooks.
- Entitlement middleware enforced at the gateway for all paid endpoints (doc 05).
- Grace, dunning, refund flows defined.
- **Exit gate:** subscription upgrades/downgrades reflect within 60s across all services.

### B5 — Hardening & Launch Readiness
- External penetration test closed.
- Load test at 3× target with no SLO violations.
- DR drill: full prod restore to an isolated region from backups.
- Privacy/TOS review closed.
- **Exit gate:** launch sign-off from engineering, security, and legal.

### B6 — Post-GA Scaling
- Multi-region active/active for stateless services; active/passive for stateful.
- Data tiering (warm/cold) automation.
- Cost attribution per tenant for pricing decisions.
- **Exit gate:** a region failure drill recovers the product within RTO without data loss.

---

## 15. Non-negotiables

- No service stores a raw private key outside the vault.
- No service logs a secret, a token, or a seed phrase.
- No change ships without a rollback plan.
- No production access without audit.
- No kill switch is ever "documented but unwired". Every switch is exercised in stage on every release.
- No tenant ever sees another tenant's data. Ever.
