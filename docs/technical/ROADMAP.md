# Sage — Production Roadmap

> **Goal**: Ship a polished, production-grade mobile trading app on Android (iOS when MWA supports it).

---

## Phase 0: Foundation (Week 1-2)

### 0.1 Project Scaffolding

- [x] Create Flutter project (`flutter create sage`)
- [ ] Set up project structure (see design-system.md §14)
- [ ] Configure `pubspec.yaml` with all packages
- [ ] Set up Riverpod, GoRouter, ScreenUtil, google_fonts
- [ ] Configure Flutter flavors: `dev`, `staging`, `prod`
- [ ] Set up CI/CD (GitHub Actions → build APK on push)
- [ ] Configure `.env` files for each environment
- [ ] Set up Dart linting rules (`analysis_options.yaml`)

### 0.2 Design System Implementation

- [ ] `SageColors` — all color constants
- [ ] `SageTypography` — Inter font, full type scale
- [ ] `SageDesign` — spacing, radius, surfaces, decorations
- [ ] `SageTheme` — ThemeData (dark primary, light secondary)
- [ ] Core widgets: `SageCard`, `SageButton`, `SageInput`, `SageTag`
- [ ] `SageBottomSheet`, `SageDialog` base components
- [ ] `PnlBadge`, `TokenListItem`, `MiniSparkline` widgets
- [ ] `ShimmerSkeleton` for every data view
- [ ] Navigation shell with bottom nav bar
- [ ] Lottie asset setup (onboarding, success, loading, empty states)

**Milestone**: App runs with full navigation, all screens show skeleton/placeholder UI. Every screen is visitable but shows no real data.

---

## Phase 1: UI Shell — All Screens (Week 3-5)

> Build every screen with hardcoded mock data. No API calls. Focus purely on pixel-perfect UI.

### 1.1 Onboarding Flow

- [ ] Splash screen with Sage logo animation
- [ ] Welcome screen (3-slide carousel with Lottie)
  - Slide 1: "Trade" — Buy/sell tokens instantly
  - Slide 2: "Automate" — Your rules, your strategies
  - Slide 3: "Sage AI" — AI-managed LP positions
- [ ] Connect wallet screen (MWA prompt)
- [ ] Quick setup complete screen

### 1.2 Home / Portfolio (Tab 1)

- [ ] Portfolio header: net worth (displayLarge), 24h change badge
- [ ] Sage AI summary card (if positions active)
- [ ] Active strategies compact list (2-3 items)
- [ ] Holdings list with token icons, prices, sparklines
- [ ] Recent activity feed (last 5 transactions)
- [ ] Pull-to-refresh with custom animation
- [ ] Empty state for new users (Lottie + CTA)

### 1.3 Swap (Tab 2)

- [ ] Token pair selector (From / To)
- [ ] Amount input with max button and USD conversion
- [ ] Swap route preview card (provider, price impact, fees)
- [ ] Swap confirmation bottom sheet
- [ ] Success animation (Lottie checkmark)
- [ ] Error state with retry
- [ ] Token search modal (search, recent, trending sections)
- [ ] Token detail bottom sheet (from search results)

### 1.4 Automate (Tab 3)

- [ ] Active strategies list view
- [ ] Strategy card component (status, stats, quick actions)
- [ ] Strategy templates gallery (pre-built starting points)
- [ ] Create strategy flow:
  - [ ] Step 1: Name + description
  - [ ] Step 2: Choose trigger type (dropdown → detail config)
    - Volume spike, Price change %, RSI cross, New pair listed, Custom
  - [ ] Step 3: Choose action (Open LP, Buy token, Sell token)
    - Configure: amount, pool type, bin range
  - [ ] Step 4: Guardrails (max positions, stop-loss, cooldown, time limit)
  - [ ] Step 5: Review & activate (summary card)
- [ ] Strategy detail screen (full trade log, performance chart, edit/pause/delete)
- [ ] Empty state for no strategies

### 1.5 Profile (Tab 4)

- [ ] Wallet info card (address, balance, copy, QR)
- [ ] Performance overview (total PnL, best trade, worst trade, win rate)
- [ ] Sage AI section:
  - [ ] Deposit/withdraw interface
  - [ ] Confidence slider (Conservative / Balanced / Aggressive)
  - [ ] Trade history list
  - [ ] Performance chart (cumulative PnL over time)
  - [ ] Kill switch toggle
- [ ] Settings list:
  - [ ] RPC endpoint configuration
  - [ ] Notification preferences
  - [ ] Security (biometric lock)
  - [ ] Theme (dark/light/system)
  - [ ] About / Legal / Version
- [ ] Disconnect wallet

### 1.6 Shared Components

- [ ] Token detail bottom sheet (chart, stats, buy/sell CTA)
- [ ] Transaction detail bottom sheet (hash, status, amounts, timestamp)
- [ ] Global notification/toast system
- [ ] Search overlay with recent + trending
- [ ] Connection status indicator (top bar)
- [ ] App-wide error boundary

**Milestone**: Complete app walkthrough possible. Every screen is built, interactive, and uses mock data. Design review sign-off.

---

## Phase 2: Wallet Integration (Week 6-7)

### 2.1 MWA Connection

- [ ] Implement `WalletService` using `solana_mobile_client`
- [ ] Authorize flow (connect to Phantom/Solflare)
- [ ] Deauthorize flow (disconnect)
- [ ] Session persistence (remember connected wallet)
- [ ] Wallet availability check (is MWA wallet installed?)
- [ ] Fallback: deep-link to Play Store if no wallet found
- [ ] Auth state provider (Riverpod) → gates all authenticated screens

### 2.2 Balance & Token Data

- [ ] Fetch SOL balance from Helius RPC
- [ ] Fetch SPL token balances (Helius DAS API)
- [ ] Token metadata resolution (name, symbol, icon, decimals)
- [ ] Token price data (Jupiter Tokens V2 API)
- [ ] Portfolio value calculation
- [ ] Auto-refresh on interval (30s) + manual pull-to-refresh
- [ ] Cache layer (Hive) for offline display

**Milestone**: User can connect wallet, see real balances and token holdings.

---

## Phase 3: Swap Engine (Week 8-9)

### 3.1 Jupiter Ultra Integration

- [ ] Implement `SwapService` wrapping Jupiter Ultra API
- [ ] Get order (quote) with token pair + amount
- [ ] Sign transaction via MWA
- [ ] Submit signed transaction to Jupiter execute endpoint
- [ ] Poll transaction status
- [ ] Display result (success/failure)
- [ ] Integrator fee configuration (0.1-0.3%)
- [ ] Error handling (slippage, insufficient balance, network)

### 3.2 Token Discovery

- [ ] Jupiter Tokens V2 search integration
- [ ] Trending tokens feed (`toptrending` category)
- [ ] Recently listed tokens (`recent` endpoint)
- [ ] Verified token indicators
- [ ] Token detail view with live price chart (fl_chart)

### 3.3 Transaction History

- [ ] Fetch parsed transactions from Helius
- [ ] Display swap history with amounts, tokens, timestamps
- [ ] Transaction detail sheet with Solscan link

**Milestone**: User can search tokens and execute real swaps via Jupiter. Transaction history shows completed trades.

---

## Phase 4: Backend Service (Week 10-12)

### 4.1 API Server

- [ ] FastAPI Python service
  - [ ] Auth: Verify wallet signature for authentication
  - [ ] Endpoints: `/predict`, `/strategies`, `/trades`, `/performance`
  - [ ] WebSocket for real-time updates
- [ ] Deploy to VPS (Hetzner/Railway)
- [ ] PostgreSQL database for:
  - [ ] User strategies (config, status)
  - [ ] Trade history
  - [ ] Model predictions log
  - [ ] User preferences
- [ ] Redis for:
  - [ ] Rate limiting
  - [ ] Market data cache
  - [ ] Active session tracking

### 4.2 Market Data Pipeline

- [ ] Meteora API poller (pool data, volume, fees)
- [ ] Helius webhook receiver (real-time transaction events)
- [ ] Feature engineering pipeline (reuse from `ml-pipeline/`)
- [ ] Data storage and TTL management

### 4.3 ML Model Serving

- [ ] Load XGBoost v3 model
- [ ] Prediction endpoint: pool features → { profitable: bool, confidence: float }
- [ ] Threshold configuration per user
- [ ] Prediction logging for model monitoring
- [ ] Model versioning (swap models without downtime)

**Milestone**: Backend is deployed, serving predictions, and storing strategy configurations.

---

## Phase 5: Strategy Automation Engine (Week 13-15)

### 5.1 Strategy Runtime

- [ ] Strategy definition schema (triggers, actions, guardrails)
- [ ] Strategy executor (server-side, runs on cron loop)
- [ ] Trigger evaluation engine:
  - [ ] Volume threshold trigger
  - [ ] Price change trigger
  - [ ] RSI/momentum trigger
  - [ ] New pair detection trigger
- [ ] Action executor:
  - [ ] Open LP position (via DLMM SDK)
  - [ ] Close LP position
  - [ ] Swap (via Jupiter)
- [ ] Guardrail enforcement:
  - [ ] Max concurrent positions
  - [ ] Cooldown per token
  - [ ] Stop-loss monitoring
  - [ ] Max daily loss limit
- [ ] Push notification on trade execution
- [ ] Strategy pause/resume API

### 5.2 Sage AI Mode

- [ ] Autonomous LP manager (extension of lp-bot trading engine)
- [ ] User deposit/withdraw flow
- [ ] Confidence threshold mapping to entry parameters
- [ ] Per-user position tracking
- [ ] Performance reporting
- [ ] Circuit breaker integration (from lp-bot safety module)
- [ ] Emergency kill switch

### 5.3 Mobile Integration

- [ ] Connect Automate screens to real strategy API
- [ ] Real-time strategy status via WebSocket
- [ ] Push notifications (Firebase Cloud Messaging)
- [ ] Strategy CRUD operations
- [ ] Sage AI deposit/withdraw via MWA signing
- [ ] Performance charts with real data

**Milestone**: Users can create strategies, see them execute trades, and monitor performance in real-time. Sage AI can autonomously manage LP positions.

---

## Phase 6: Polish & Hardening (Week 16-18)

### 6.1 Security

- [ ] Biometric app lock (flutter_secure_storage)
- [ ] Transaction confirmation flow (amount review + biometric)
- [ ] Rate limiting on all API endpoints
- [ ] Input sanitization / validation
- [ ] No PII stored on device
- [ ] SSL pinning for API calls
- [ ] Penetration testing on backend

### 6.2 Performance

- [ ] API response caching strategy (stale-while-revalidate)
- [ ] Image/icon caching
- [ ] Lazy loading for lists
- [ ] Pagination for trade history
- [ ] Memory profiling (no leaks)
- [ ] Startup time optimization (<2s cold start)

### 6.3 Testing

- [ ] Unit tests for all services, providers, formatters
- [ ] Widget tests for core components
- [ ] Integration tests for critical flows (connect → swap → verify)
- [ ] Backend API tests
- [ ] Model prediction accuracy monitoring
- [ ] Load testing on backend (100 concurrent users)

### 6.4 Legal & Compliance

- [ ] Terms of Service
- [ ] Privacy Policy
- [ ] Risk disclaimers (Sage AI, automation)
- [ ] Non-custody disclosure
- [ ] GDPR-compliant data handling

### 6.5 UX Polish

- [ ] Micro-interaction audit (every tap has feedback)
- [ ] Loading state audit (every async operation has skeleton)
- [ ] Error state audit (every failure has recovery path)
- [ ] Empty state audit (every list has empty illustration)
- [ ] Accessibility audit (contrast, touch targets, screen reader)
- [ ] Dark/light theme completeness check

**Milestone**: App is secure, performant, and polished. Ready for beta.

---

## Phase 7: Launch (Week 19-20)

### 7.1 Beta

- [ ] Internal testing (team)
- [ ] Closed beta (50 users from LP Army / Meteora community)
- [ ] Feedback collection and critical bug fixes
- [ ] Performance monitoring in production

### 7.2 Public Launch

- [ ] Google Play Store listing (screenshots, description, video)
- [ ] Solana dApp Store submission
- [ ] Landing page (web)
- [ ] Social media announcement
- [ ] Community onboarding documentation
- [ ] Support channel setup (Discord / Telegram)

### 7.3 Post-Launch

- [ ] Monitor Sage AI performance daily
- [ ] Retrain model with live data (monthly)
- [ ] User feedback triage
- [ ] Feature requests prioritization
- [ ] iOS readiness tracking (waiting on MWA iOS support)

---

## Phase Summary

| Phase | Duration | Deliverable |
|-------|----------|-------------|
| **0. Foundation** | 2 weeks | Project scaffold + design system |
| **1. UI Shell** | 3 weeks | All screens built with mock data |
| **2. Wallet** | 2 weeks | MWA connection + real balances |
| **3. Swap** | 2 weeks | Live token swaps via Jupiter |
| **4. Backend** | 3 weeks | API server + ML model serving |
| **5. Automation** | 3 weeks | Strategy engine + Sage AI |
| **6. Polish** | 3 weeks | Security, testing, UX polish |
| **7. Launch** | 2 weeks | Beta → public release |
| **Total** | **~20 weeks** | **Production app on Play Store** |

---

## Technical Risks & Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| MWA only works on Android | 50% market excluded | Track iOS MWA progress; consider Privy SDK as fallback for iOS |
| Jupiter Ultra API changes | Swap flow breaks | Pin API version; abstract behind `SwapService` interface |
| ML model degrades in live markets | Bad trades, user trust lost | Conservative default threshold; circuit breaker; daily monitoring |
| Server downtime kills automation | Strategies stop executing | Health monitoring; auto-restart; notify users on downtime |
| Solana network congestion | Failed transactions | Retry with backoff; priority fee escalation; Helius premium RPC |
| Flutter + Solana ecosystem gaps | Missing SDK features | Contribute upstream; write native channel bridges where needed |

---

## Decision Log

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Framework | Flutter | Cross-platform, existing team expertise, rich animation ecosystem |
| State management | Riverpod | Proven in Dream, compile-safe, testable |
| Icons | HugeIcons | 4,700+ consistent stroke icons, tree-shaking, MIT license |
| Font | Inter | Superior number readability vs Poppins, variable font |
| Swap provider | Jupiter Ultra | RPC-less, gasless, MEV protection, 3-step integration |
| Wallet | Solana MWA | Non-custodial, standard protocol, no key management |
| Charts | fl_chart | Native Flutter, highly customizable, supports touch interactions |
| Backend | FastAPI (Python) | ML model is Python, reuses ml-pipeline code |
| Database | PostgreSQL | Relational integrity for trades/strategies |
| ML model | XGBoost v3 | Trained on 200K+ data points, proven in simulation |
| Hosting | Hetzner VPS | Cost-effective, EU/US regions, dedicated resources |
