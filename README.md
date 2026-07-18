# Pitaka

"Pitaka" is the Filipino word for "wallet" — simple as that. It's basically your wallet, but digital, and it actually tells you where your money is going.

Pitaka is an open source personal finance tracker built specifically for Filipinos who juggle multiple banks, e-wallets, and credit accounts. There isn't really an app out there that focuses on Philippine banks and e-wallets, so I decided to build my own — mainly for personal use, but hopefully it can help others too.

## Why I built this

Honestly, I was struggling to track my money across GCash, Maya, and my bank accounts. I got tired of using Excel sheets that I kept forgetting to update. So as a fresh grad with some background in Flutter, I decided to try building my own solution.

This is very much a work in progress and a personal learning project, so expect bugs (and hopefully fixes too as I learn more).

## Privacy First

No cloud, no accounts, no tracking. All data is stored locally on your device using SQLite. There is no backend server — the app talks directly to a local database file. Nobody has access to your data but you.

## Features

* **Dashboard** — See all your assets in one screen *(planned)*
* **Accounts** — Manually add your accounts and track your net worth
* **Transactions** — View all your transactions in one place *(planned)*
* **Daily Limit** — Set a daily spending limit to help you stay on track with your financial goals *(planned)*
* **Daily Interest** — Automatically adds daily interest based on your bank, so you don't have to calculate it manually *(planned)*

## Tech Stack

* **Flutter** — cross-platform UI (Android and iOS)
* **SQLite** (via `sqflite`) — local, embedded database. No server, no API — all data lives in a single local database file.
* **Riverpod** (`flutter_riverpod`) — state management, bridges the local database to the UI
* **intl** — currency and date formatting

## Architecture

Pitaka is local-first with no backend:

```
UI (Screens) → Riverpod Providers → DAOs → SQLite
```

Full details in [DOCUMENTATION.md](./DOCUMENTATION.md).

## Getting Started

**Prerequisites:**
* [Flutter SDK](https://docs.flutter.dev/get-started/install) installed
* An Android/iOS emulator, or a physical device with USB debugging enabled

**Setup:**
```bash
git clone https://github.com/<your-username>/pitaka.git
cd pitaka
flutter pub get
flutter run
```