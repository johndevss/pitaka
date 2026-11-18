# Pitaka (Wallet)

*"Pitaka"* is the Filipino word for **wallet**. It's your digital wallet tracker — simple, fast, completely free, and transparent.

Pitaka is a 100% open-source, local-first personal finance tracker built specifically for Filipinos juggling multiple Philippine bank accounts, e-wallets, credit cards, and cash.

---

## Why I Built This

As a fresh graduate trying to manage my own finances, I was genuinely frustrated with existing budget apps. Almost every finance app on the Play Store or App Store locks essential features — like adding more than 2 accounts, creating custom categories, tracking transfers, or exporting data — behind aggressive paywalls and monthly subscriptions.

I got tired of updating messy Excel sheets that I kept forgetting to sync, and I didn't want to pay a monthly subscription just to track my own hard-earned money. 

So, I decided to build **Pitaka**: a finance app that is **100% free, open-source, and paywall-free forever**. No ads, no monthly sub, no locked features, and no corporate tracking.

---

## Features

- **Tailored for PH Institutions**: Pre-configured profiles for Philippine banks and e-wallets (SeaBank, Maya, GoTyme, GCash, BDO, BPI, CIMB, Tonik, Maribank, DiskarTech, etc.).
- **Automated Daily Interest Engine**: Automatically calculates daily high-yield savings interest (including the 20% PH withholding tax deduction and tiered caps) and auto-posts payouts directly to your accounts.
- **Paywall-Free & Open Source**: Every single feature is unlocked for everyone. No premium tiers, no subscriptions.
- **Privacy First & Local-Only**: Your financial data never leaves your phone. All data is stored locally in an embedded SQLite database. No cloud servers, no mandatory account sign-up, and zero tracking.
- **Accounts & Net Worth Tracking**: Track Wallet, Savings, Credit, and Cash accounts with live balance calculation.
- **Atomic Inter-Account Transfers**: Easily move funds between accounts (e.g. BDO to Maya) with real-time balance validation.
- **Expense & Income Categorization**: Organize transactions with custom icons, color accents, and dedicated Expense/Income tabs.
- **Daily Spending Limits**: Set daily budget limits to help keep your daily spending on track.
- **In-App Release Updates**: Built-in GitHub release updater allowing you to check for and install new app updates directly within Pitaka.

---

## Privacy & Local-First Philosophy

- **No Cloud Database**: No backend server exists.
- **No Accounts Required**: Open the app and start using it immediately.
- **Your Data is Yours**: Stored in a local `pitaka.db` file on your device. Backup and control your own data anytime.

---

## Tech Stack

- **[Flutter](https://flutter.dev/)** — Cross-platform mobile UI framework.
- **[SQLite](https://pub.dev/packages/sqflite)** (`sqflite`) — Local embedded database running in WAL (Write-Ahead Logging) mode.
- **[Riverpod](https://riverpod.dev/)** (`flutter_riverpod`) — Reactive state management bridging local database state to UI.
- **[Intl](https://pub.dev/packages/intl)** — Locale-aware currency formatting supporting PHP (₱), USD ($), and custom ISO currencies.

---

## Architecture & Documentation

Pitaka is built using **Feature-First Clean Architecture**.

Detailed documentation regarding codebase structure, database schemas, interest calculation math, and testing can be found in the **[`docs/`](docs/README.md)** directory:

- **[Architecture Overview](docs/architecture.md)**
- **[File Structure Reference](docs/file-structure.md)**
- **[Database Schema & Triggers](docs/database-schema.md)**
- **[Design Decisions & Interest Engine](docs/design-decisions.md)**
- **[Testing Guide](docs/testing.md)**
- **[Status & Roadmap](docs/status-and-roadmap.md)**

---

## Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (v3.0.0 or higher)
- Android Studio / VS Code with Flutter extension
- An Android/iOS emulator or physical device

### Running Locally

```bash
# 1. Clone the repository
git clone https://github.com/johndevss/pitaka.git

# 2. Navigate to project root
cd pitaka

# 3. Install dependencies
flutter pub get

# 4. Run the app
flutter run
```

### Running Tests

```bash
flutter test
```

---

## Contributing

Contributions, feedback, bug reports, and feature suggestions are very welcome! If you're a student, fresh grad, or developer wanting to build something cool for the PH dev community:

1. Fork the repo.
2. Create your feature branch (`git checkout -b feature/AmazingFeature`).
3. Commit your changes (`git commit -m 'feat: Add some AmazingFeature'`).
4. Push to the branch (`git push origin feature/AmazingFeature`).
5. Open a Pull Request.

---

## License

This project is licensed under the [MIT License](LICENSE.md) — free to use, modify, and distribute.