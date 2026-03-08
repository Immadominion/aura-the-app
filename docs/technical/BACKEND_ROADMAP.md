# Sage Backend — Implementation Roadmap

> **Target**: MONOLITH Hackathon (March 9, 2026)  
> **Start**: February 27, 2026  
> **Days Remaining**: 10  
> **System Design**: See [BACKEND_SYSTEM_DESIGN.md](BACKEND_SYSTEM_DESIGN.md)

---

## Sprint Overview

| Sprint | Days | Focus | Deliverable |
|--------|------|-------|-------------|
| **S1** | Feb 27-28 | Foundation | API scaffold, auth, database |
| **S2** | Mar 1-2 | Bot Engine | Orchestrator, engine integration |
| **S3** | Mar 3-4 | Flutter Wiring | App ↔ backend integration |
| **S4** | Mar 5-6 | ML + Polish | Sage AI mode, real-time updates |
| **S5** | Mar 7-8 | Demo Prep | Demo video, README, submission |

---

## S1: Foundation (Feb 27-28)

### S1.1 Project Scaffold ✅

- [ ] Initialize `sage-backend/` project
  - Hono + Node.js (or Express 5 if Hono causes friction)
  - TypeScript strict mode
  - Zod for validation
  - ESM modules
- [ ] Dependencies:
  - `hono`, `@hono/node-server`, `@hono/zod-validator`
  - `@solana/web3.js`, `jose` (JWT), `drizzle-orm` / raw `pg`
  - `ws` (WebSocket), `ioredis` (optional, can skip for MVP)
  - `dotenv`, `zod`
- [ ] Config with Zod validation (PORT, DATABASE_URL, SOLANA_RPC, HELIUS_KEY, JWT_SECRET)
- [ ] Health endpoint with DB + Solana connectivity check
- [ ] Error handling middleware
- [ ] Request logging middleware

### S1.2 Database Setup

- [ ] Supabase project created (free tier)
- [ ] Schema migration: users, bots, positions, trade_log, strategy_presets
- [ ] Database client module (connection pooling)
- [ ] Seed system presets (FreesolGames, Conservative, Heart Attack, Slow & Steady)

### S1.3 Authentication (SIWS)

- [ ] `POST /auth/nonce` — generate + store nonce (5min TTL)
- [ ] `POST /auth/verify` — verify Ed25519 signature, upsert user, return JWT
- [ ] `POST /auth/refresh` — refresh token rotation
- [ ] Auth middleware (JWT validation on protected routes)
- [ ] Test: full auth flow with a test wallet

### S1.4 Seal Service (Port from existing backend)

- [ ] Move wallet/agent/session logic into `services/seal.ts`
- [ ] Adapt routes to use auth middleware (user-scoped)
- [ ] `POST /wallet/create` — prepare Seal wallet tx (requires auth)
- [ ] `GET /wallet/state` — get authenticated user's wallet
- [ ] `GET /wallet/balance` — user's Seal wallet balance
- [ ] Test against devnet

**S1 Exit Criteria**: User can authenticate via wallet signature, backend creates JWT, Seal wallet endpoints work with auth.

---

## S2: Bot Engine (Mar 1-2)

### S2.1 Engine Adapter

- [ ] Copy/adapt lp-bot core modules into `sage-backend/src/engine/`:
  - `trading-engine.ts` — core scan/entry/exit loop
  - `simulation.ts` — SimulationExecutor (for demo mode)
  - `market-data.ts` — MarketDataProvider + SharedAPICache
  - Types: BotConfig, ITradingExecutor, IMarketDataProvider
- [ ] Replace JSON file persistence with database writes
- [ ] Replace console logging with structured events
- [ ] Add event emitter (position open/close/update → EventBus)

### S2.2 Bot Orchestrator

- [ ] `BotOrchestrator` class:
  - `createBot(userId, config)` → save to DB
  - `startBot(botId)` → instantiate TradingEngine, begin CRON
  - `stopBot(botId)` → graceful shutdown
  - `pauseBot(botId)` → stop scanning, keep positions
  - `getBotStatus(botId)` → return stats
  - `emergencyStop(botId)` → close all positions immediately
- [ ] Per-bot config from database (not env vars)
- [ ] Shared MarketDataProvider across all bots (SharedAPICache)
- [ ] Bot state recovery on server restart (resume running bots)

### S2.3 Bot API Routes

- [ ] `POST /bot/create` — create bot with config, default: stopped
- [ ] `GET /bot/list` — list user's bots with status
- [ ] `GET /bot/:id` — bot detail + live stats
- [ ] `PUT /bot/:id/config` — update config (stopped bots only)
- [ ] `POST /bot/:id/start` — start bot (simulation mode for MVP)
- [ ] `POST /bot/:id/stop` — stop bot
- [ ] `POST /bot/:id/emergency` — emergency close all
- [ ] `DELETE /bot/:id` — delete stopped bot

### S2.4 Strategy Presets

- [ ] `GET /strategy/presets` — list system + user presets
- [ ] `POST /strategy/create` — save custom strategy
- [ ] Apply preset → populate bot config on creation

**S2 Exit Criteria**: Can create a bot via API, start it in simulation mode, see it scanning markets, opening/closing simulated positions. Stats returned via API.

---

## S3: Flutter Wiring (Mar 3-4)

### S3.1 API Client in Sage

- [ ] Create `sage/lib/core/services/api_client.dart`
  - Base URL config (dev/staging/prod)
  - JWT token storage (secure storage)
  - Automatic token refresh
  - Error handling + retry
- [ ] Create `sage/lib/core/services/auth_service.dart`
  - SIWS flow: get nonce → MWA sign → verify → store JWT
  - Auto-reconnect on app resume

### S3.2 Onboarding Flow Update

- [ ] After wallet connect → call `POST /auth/verify`
- [ ] Setup sheet (choose mode, fund agent, risk profile)
- [ ] `POST /wallet/create` → MWA sign → send tx
- [ ] `POST /bot/create` with selected config
- [ ] Navigate to Home with real data

### S3.3 Home Screen — Live Data

- [ ] Replace hardcoded mock data with API calls
- [ ] `GET /bot/list` → show bot status on home
- [ ] `GET /position/active` → show active positions
- [ ] `GET /wallet/balance` → show balance
- [ ] Real-time updates via WebSocket (bot status, position changes)

### S3.4 Bot Control UI

- [ ] Start/stop/pause buttons connected to API
- [ ] Emergency stop button (prominent, red)
- [ ] Strategy config sheet (edit parameters)
- [ ] Position list with PnL display

**S3 Exit Criteria**: Full flow works on Android: connect wallet → setup → start bot → see positions appear in real-time (simulation mode).

---

## S4: ML + Polish (Mar 5-6)

### S4.1 ML Service

- [ ] Load pre-trained XGBoost model (JSON export, runs in Node.js)
  - Option: Use `xgboost-node` or `ml-xgboost` npm package
  - Option: Embed Python FastAPI sidecar (if Node packages insufficient)
- [ ] `POST /ml/predict` — internal endpoint, takes pool features
- [ ] `GET /ml/status` — model version, accuracy metrics
- [ ] Integrate with TradingEngine: when mode='sage-ai', add ML score to entry decision

### S4.2 Sage AI Mode in App

- [ ] Delegate screen (Mode 3) shows real data:
  - Capital deployed, model confidence, PnL
  - Risk dial (Conservative / Balanced / Aggressive)
  - Kill switch
- [ ] Confidence indicator from ML model
- [ ] Trade decision log ("Model entered SOL-USDC at 82% confidence")

### S4.3 WebSocket Integration

- [ ] WebSocket server in backend (`/ws` upgrade)
- [ ] Client-side WebSocket in Flutter
- [ ] Real-time events: position open/close, balance changes, alerts
- [ ] Reconnection logic with exponential backoff

### S4.4 Position & Trade History

- [ ] `GET /position/active` — all active positions with live PnL
- [ ] `GET /position/history` — closed positions
- [ ] `GET /position/:id` — full position detail
- [ ] History screen in app (Layer 4 — Forensics)

**S4 Exit Criteria**: Sage AI mode works end-to-end in simulation. ML model provides predictions. WebSocket streams live updates to app.

---

## S5: Demo Prep (Mar 7-8)

### S5.1 Demo Mode Polish

- [ ] Ensure simulation creates realistic-looking data
- [ ] Seed demo account with historical positions (for impressive screenshots)
- [ ] Bot dashboard shows clean stats (win rate, PnL graph)
- [ ] All screens responsive, no broken states

### S5.2 Demo Video (3-5 min)

Script outline:

1. Open app → onboarding animation (5s)
2. Connect Phantom wallet via MWA (10s)
3. Setup sheet: choose "Both" mode (rule-based + AI) (15s)
4. Fund agent wallet with 5 SOL (10s)
5. Start bot → show scanning animation (10s)
6. Switch to Mode 1 (Delegate) → show ML confidence + positions (10s)
7. Switch to Mode 2 (Automate) → show strategy running (10s)
8. Drill into position → show PnL, fees, entry rationale (10s)
9. Show emergency stop (5s)
10. Architecture slide: Seal session keys (15s)
11. Summary: what makes Sage unique (10s)

- [ ] Record on Android device (screen record)
- [ ] Edit with simple cuts (no fancy effects)
- [ ] Add voiceover or text captions

### S5.3 Submission Package

- [ ] README.md (project description, architecture, how to run)
- [ ] Screenshots (4-6 key screens)
- [ ] GitHub repo cleanup (remove sensitive files, clean .env.example)
- [ ] Deploy backend to Railway/Fly.io (public URL)
- [ ] Submit on MONOLITH platform before March 9

---

## Risk Mitigation

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| Hono learning curve delays | Medium | 1 day | Fallback to Express 5 (already proven) |
| CPI depth issue with Seal → Meteora | High | Critical | Ship simulation mode; document live mode as "next sprint" |
| Supabase free tier limits | Low | Medium | SQLite/Turso as backup |
| ML model doesn't load in Node.js | Medium | Medium | Pre-compute predictions at pool refresh time |
| Flutter WebSocket reliability | Medium | Low | Fallback to polling (10s interval) |
| Time crunch | High | High | S5 is buffer. If S4 slips, ship without ML and call it "rule-based LP automation" |

---

## Priority Order (If Time Is Short)

If we only have time for the essentials, ship in this order:

1. **Auth** (SIWS) — without this, nothing works
2. **Bot create/start/stop** — the core value prop
3. **Simulation mode** — demo-able without real money
4. **Flutter integration** (home + bot control) — the "mobile" differentiator
5. **Strategy presets** — "configure in 10 seconds" UX
6. **WebSocket** — real-time wow factor
7. **Sage AI** — the ML differentiator
8. **Trade history** — nice to have
9. **Live execution** — can demo without it

Items 1-5 are achievable in 6 days. Items 6-7 need the remaining 4. Items 8-9 are stretch goals.

---

## Definition of Done

The MONOLITH submission is ready when:

- [ ] User can connect wallet and authenticate
- [ ] User can configure and start a bot in simulation mode
- [ ] App shows real-time bot status and simulated positions
- [ ] At least one "wow moment" (ML confidence display OR live position tracking)
- [ ] 3-5 minute demo video recorded
- [ ] Backend deployed and accessible
- [ ] README explains what Sage is and why it matters
