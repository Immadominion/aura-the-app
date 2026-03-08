# Production Hardening Audit — Status Tracker

> **Last Updated**: February 28, 2026  
> **Scope**: sage-backend, sage (Flutter), seal (on-chain)

---

## Summary

| Component | Critical | High | Medium | Fixed | Remaining |
|-----------|----------|------|--------|-------|-----------|
| **sage-backend** | 6 | 8 | 10 | 8 ✅ | 16 |
| **sage (Flutter)** | 7 | 6 | 8 | 4 ✅ | 17 |
| **seal (on-chain)** | 4 | 5 | 6 | 0 | 15 |
| **Total** | **17** | **19** | **24** | **12** | **48** |

---

## sage-backend — Fixed Issues ✅

### CRITICAL (6/6 Fixed)

1. **✅ No Rate Limiting** → Tiered rate limiting via `hono-rate-limiter@0.5.3`
   - Auth: 10/min, Bot lifecycle: 30/min, Reads: 120/min, ML: 30/min, Global: 300/min
   - File: `src/middleware/rate-limit.ts`

2. **✅ CORS Wildcard in Production** → CORS locked down
   - Auto-blocks wildcard `*` in production mode
   - Configurable `CORS_ORIGIN` env var
   - File: `src/index.ts`

3. **✅ JWT Access Token 24h Lifetime** → 15-minute access tokens in production
   - Access: 15m (prod) / 24h (dev), Refresh: 7d (prod) / 30d (dev)
   - File: `src/config.ts`

4. **✅ EmergencyStop Resets on Restart** → State persisted to SQLite
   - `emergencyStopState` column added to bots table
   - `serializeState()` / `deserializeState()` methods
   - State restored on bot recovery, saved after each position close + before stop
   - Files: `src/db/schema.ts`, `src/engine/emergency-stop.ts`, `src/engine/orchestrator.ts`

5. **✅ ML Feedback Endpoint Unauthenticated** → Requires `requireAuth`
   - File: `src/routes/ml.ts`

6. **✅ Bot Start/Stop Race Conditions** → `botLocks` Set prevents concurrent operations
   - Wrapped `startBot`/`stopBot` with lock acquisition/release
   - File: `src/engine/orchestrator.ts`

### HIGH (2/8 Fixed)

1. **✅ No Body Size Limits** → 1MB body limit via Hono `bodyLimit()` middleware
   - File: `src/index.ts`

2. **✅ No Secure HTTP Headers** → `secureHeaders()` + `requestId()` middleware
   - File: `src/index.ts`

### Remaining HIGH

- [ ] Per-user wallet isolation (bots share server wallet)
- [ ] Database backup strategy
- [ ] Structured error responses (some endpoints return raw error strings)
- [ ] Request validation on all endpoints (some miss Zod)
- [ ] Graceful shutdown waits for active trades
- [ ] Health endpoint should check DB + RPC connectivity

### Remaining MEDIUM

- [ ] Bot status SSE should have heartbeat/reconnect
- [ ] API versioning (v1 prefix)
- [ ] Proper HTTP status codes (some return 200 on errors)
- [ ] Token rotation on refresh (invalidate old refresh)
- [ ] Drizzle migration files instead of `push` for production
- [ ] Connection pooling settings
- [ ] Environment-specific logging levels
- [ ] Audit trail for config changes
- [ ] Position close reason in trade_log
- [ ] Dead letter queue for failed SSE events

---

## sage (Flutter) — Fixed Issues ✅

### CRITICAL (2/7 Fixed)

1. **✅ Hardcoded localhost URLs** → `EnvConfig` system with `--dart-define`
   - Supports development/staging/production environments
   - Custom URL override via `--dart-define=API_BASE_URL=`
   - File: `lib/core/config/env_config.dart`

2. **✅ No Input Validation on Financial Parameters** → Full validation system
   - `BotConstraints` class matching backend Zod schema
   - `BotValidators` class with form-field validators
   - `_EditConfigSheet` now uses `Form` + `TextFormField` with validators
   - `_ConfigField` has `inputFormatters` + `autovalidateMode.onUserInteraction`
   - Live mode confirmation dialog on bot creation
   - Files: `lib/core/utils/bot_validators.dart`, `lib/features/automate/presentation/strategy_detail_screen.dart`, `lib/features/automate/presentation/create_bot_sheet.dart`

### HIGH (2/6 Fixed)

1. **✅ API Client Updated** → Uses `EnvConfig.apiBaseUrl` instead of hardcoded URLs
   - Timeouts from `EnvConfig` (connect: 10s, receive: 30s)
   - File: `lib/core/services/api_client.dart`

2. **✅ Profile Screen Dynamic** → Shows environment, API host, ML host from `EnvConfig`
   - File: `lib/features/wallet/presentation/profile_screen.dart`

### Remaining CRITICAL

- [ ] No crash reporting (Sentry/Crashlytics)
- [ ] GoRouter recreated on auth state change (possible navigation bugs)
- [ ] No connectivity monitoring (app silent when offline)
- [ ] No app lifecycle handling (pause/resume)
- [ ] iOS wallet support (WalletConnect/Phantom deep links)

### Remaining HIGH

- [ ] Pull-to-refresh on data screens
- [ ] SSE reconnection on connection drop
- [ ] Biometric auth for live mode
- [ ] Token refresh retry logic

### Remaining MEDIUM

- [ ] Deep link handling (app links)
- [ ] Splash screen / loading state
- [ ] Localization infrastructure
- [ ] Accessibility (semantic labels)
- [ ] App size optimization
- [ ] Screenshot/screen recording protection for wallet screens
- [ ] Keyboard handling on numeric inputs
- [ ] Dark/light theme persistence

---

## seal (on-chain) — All Remaining

### CRITICAL (4)

- [ ] **Spending limits unenforceable** — No lamport delta verification pre/post CPI
- [ ] **Single guardian takeover** — Only 1-of-1 guardian recovery, needs m-of-n
- [ ] **CPI self-reference** — Program can call itself, potential re-entrancy
- [ ] **Backend tx builders incompatible** — `seal/backend/` transaction builders don't match current program

### HIGH (5)

- [ ] Missing `RemoveGuardian` instruction
- [ ] Missing `LockWallet` emergency instruction
- [ ] `allowed_programs` should default-deny
- [ ] Guardian recovery should have time-lock
- [ ] No spending limit per token mint

### MEDIUM (6)

- [ ] No session key rotation
- [ ] No batch transaction support
- [ ] Rent-exempt enforcement on PDA accounts
- [ ] Test coverage for edge cases (concurrent sessions)
- [ ] Documentation for integration
- [ ] Gas estimation for complex transactions

---

## Verification Log

| Date | Action | Result |
|------|--------|--------|
| Feb 28 | npm packages verified online | All latest (dlmm 1.9.3, web3.js 1.98.4, spl-token 0.4.14, hono 4.12.3, drizzle 0.45.1) |
| Feb 28 | `hono-rate-limiter@0.5.3` installed | ✅ |
| Feb 28 | `npx tsc --noEmit` | ✅ Clean compile |
| Feb 28 | `dart analyze` | ✅ (0 errors, 0 warnings) |
| Feb 28 | `drizzle-kit push` | ✅ Schema applied |
| Feb 28 | Backend boot test | ✅ Starts, recovers bots, shuts down gracefully |
