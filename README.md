# Sage — AI-Powered LP Trading for Solana

Mobile-first autonomous liquidity provision on Meteora DLMM, powered by ML signals and secured by the Seal on-chain wallet.

Built for the **Solana Mobile Hackathon 2025**.

## Download

[**Download Sage v1.0.0 APK**](https://github.com/Immadominion/sage/releases/download/v1.0.0/sage-v1.0.0.apk) — Android 7.0+ (API 24)

> Requires a Solana wallet app (Phantom, Solflare, etc.) installed on your device.

## Features

- **Wallet Connect** — Sign-In With Solana via Mobile Wallet Adapter (Phantom, Solflare)
- **Seal Wallet** — On-chain smart wallet with session keys, spending limits, and guardian recovery
- **Automate** — Create and manage autonomous LP trading bots
- **ML Signals** — XGBoost model trained on historical Meteora data predicts profitable entry points
- **Fleet Management** — Run multiple bots with different strategies simultaneously
- **Real-time Updates** — Server-Sent Events stream live position/P&L data
- **AI Chat** — Natural language bot management (voice + text)
- **Swap** — Quick token swap interface

## Tech Stack

| Component | Technology |
|-----------|-----------|
| Framework | Flutter 3.x (Dart) |
| State | Riverpod + code generation |
| Routing | GoRouter |
| Wallet | MWA via `solana_mobile_client` |
| On-chain | Seal smart wallet (`seal_dart` SDK) |
| HTTP | Dio |
| SSE | `flutter_client_sse` |
| Charts | fl_chart |
| UI | Material 3 + Google Fonts + Phosphor Icons |

## Architecture

```
lib/
├── core/              # Config, models, services, providers
│   ├── config/        # Environment configuration (dart-define)
│   ├── models/        # Data models (wallet, position, bot)
│   ├── providers/     # Riverpod providers (API, SSE, auth)
│   └── services/      # Auth, MWA, HTTP client
├── features/          # Feature modules
│   ├── auth/          # Login + SIWS flow
│   ├── automate/      # Bot creation & management
│   ├── chat/          # AI assistant
│   ├── fleet/         # Multi-bot dashboard
│   ├── home/          # Main dashboard
│   ├── onboarding/    # First-run experience
│   ├── setup/         # Seal wallet setup
│   ├── splash/        # App splash screen
│   ├── swap/          # Token swap
│   └── wallet/        # Wallet & balance views
├── shared/            # Common widgets & utilities
└── main.dart          # Entry point
```

## Getting Started

### Prerequisites

- Flutter SDK `^3.11.0`
- Android Studio / Xcode
- A Solana wallet app (Phantom or Solflare) installed on your device/emulator
- The sage-backend running locally or deployed

### Run in Development

```bash
# Install dependencies
flutter pub get

# Run code generation (Riverpod, Freezed, JSON serialization)
dart run build_runner build --delete-conflicting-outputs

# Start the app (connects to localhost:3001 by default)
flutter run
```

### Build Release APK

```bash
# Build with production backend URL
flutter build apk --release \
  --dart-define=ENV=production \
  --dart-define=API_BASE_URL=https://<your-backend-url> \
  --dart-define=SOLANA_RPC_URL=https://<your-rpc-url>

# APK output: build/app/outputs/flutter-apk/app-release.apk
```

### Install APK on Android

1. Download the APK from [GitHub Releases](../../releases)
2. On your Android device, go to **Settings → Security → Install unknown apps**
3. Enable installation from your browser/file manager
4. Open the APK file to install
5. Launch Sage and connect your Solana wallet

### Environment Configuration

The app is configured via `--dart-define` flags at build time:

| Variable | Default | Description |
|----------|---------|-------------|
| `ENV` | `development` | `development`, `staging`, or `production` |
| `API_BASE_URL` | `http://localhost:3001` | Backend API URL |
| `SOLANA_RPC_URL` | Public devnet/mainnet | Solana RPC endpoint |
| `ML_BASE_URL` | `{API_BASE_URL}/ml` | ML prediction service |

## Backend

See [sage-backend/](../sage-backend/) for the REST API that powers the app.

## On-Chain Wallet

See [seal/](../seal/) for the Seal smart wallet program deployed on Solana.

## License

Apache-2.0
