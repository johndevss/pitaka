# AGENTS.md — AI Development Guidelines for Pitaka

This file contains repository rules, architectural guidelines, database constraints, and performance best practices for AI agents (and human contributors) working on the **Pitaka** codebase.

---

## Core Project Context

- **App Name**: Pitaka ("Wallet" in Tagalog)
- **Domain**: Local-first personal finance tracker built for Filipinos.
- **Key Philosophy**: 100% free, open-source, local-only storage (no cloud backend), zero paywalls, zero tracking.
- **Tech Stack**:
  - **Framework**: Flutter (Dart)
  - **Database**: Embedded SQLite via `sqflite` (WAL mode enabled)
  - **State Management**: Riverpod (`flutter_riverpod`)
  - **Formatting**: `intl` (`NumberFormat.simpleCurrency`)
  - **Unit Testing**: `flutter_test`, `sqflite_common_ffi`

---

## ⚡ Code Efficiency, Performance & Best Practices

All code written for Pitaka MUST prioritize maximum performance, clean architecture, and Flutter best practices:

### 1. Database & Query Efficiency (Avoid N+1 Queries)
- **Single-Pass Queries**: Always write single-pass SQL queries with `JOIN` or aggregate functions (`SUM`, `COUNT`) in DAOs. Never perform queries inside `for` loops (N+1 query antipattern).
- **Use Database Views & Triggers**: Leverage pre-aggregated views (`v_daily_analytics`, `v_monthly_category_analytics`) and triggers (`trg_update_daily_snapshot_insert`) for analytics instead of writing expensive ad-hoc joins in UI widgets.
- **Indexed Queries**: Ensure queries filter by indexed columns (`transaction_date`, `account_id`, `category_id`, `type`).

### 2. Main-Thread & Rendering Optimization
- **Pure `build()` Methods**: Never run database operations, async futures, or heavy data processing inside a Flutter widget's `build()` method. Delegate all state fetching to Riverpod providers.
- **Use `const` Constructors**: Always mark static widgets and design tokens with `const` to minimize widget subtree re-renders.
- **Asset & State Pre-Warming**: Pre-cache image assets and pre-warm core Riverpod providers during app startup in `main.dart`.
- **Downsampling & Image Caching**: Specify `cacheWidth` and `cacheHeight` constraints when loading network/asset images to minimize CPU and RAM overhead during scrolling.

### 3. Code Cleanliness, Null Safety & Defensive Programming
- **Immutable Models**: All domain models must be immutable with `final` fields, `copyWith()`, `toMap()`, and `fromMap()`.
- **Safe Type Casting**: SQLite can return integer numbers for double columns in aggregate queries. Always cast numeric DB reads safely via `(map['field'] as num?)?.toDouble()`.
- **Thin UI Components**: Keep widgets focused strictly on presentation. Put business rules in `services/`, database operations in `data/`, and state handling in `controllers/`.
- **No Dead Code**: Keep codebase lean. Remove unused packages, obsolete fields, and redundant variables immediately.

---

## Architecture & Codebase Layout

Pitaka strictly follows **Feature-First Clean Architecture**. Never create flat top-level layers (e.g. do not put files directly into `lib/models/` or `lib/screens/`).

```
lib/
├── main.dart
├── core/                   # Shared cross-cutting infrastructure & UI
│   ├── database/           # Database connection, schemas, triggers, views
│   ├── providers/          # Global providers (e.g. app updater state)
│   ├── services/           # Global services (GitHub release updater, APK downloader)
│   ├── theme/              # Central design tokens & AppTheme styling
│   ├── utils/              # Pure utility functions (formatting, icons, page transitions)
│   └── widgets/            # Shared custom widgets (Keypad, Toast, Nav Bar, Tiles)
└── features/               # Domain-driven feature modules
    ├── account/            # Account entity, institution registry, interest engine & worker
    ├── category/           # Categories manager, type filters, system category protection
    ├── dashboard/          # Home shell, equity banner, daily spending limits
    └── transaction/        # Expense/Income entry, inter-account transfers, transaction history
```

### Feature Directory Structure
Every feature under `lib/features/<feature>/` must adhere to these sub-folders:
- `models/`: Immutable Dart domain classes (`toMap`, `fromMap`, `copyWith`).
- `data/`: Data Access Objects (DAOs) interacting directly with SQLite.
- `services/`: Feature-specific business logic engines and background workers.
- `controllers/`: Riverpod providers managing state and bridging DAOs to presentation.
- `presentation/`: UI screens, widgets, and dialogs (`ConsumerWidget` / `ConsumerStatefulWidget`).

---

## Mandatory Architectural & State Rules

### 1. State Management & Provider Invalidation (Riverpod)
- DAOs are provided via `Provider<SomeDao>` (e.g. `accountDaoProvider`).
- Data feeds are exposed via `FutureProvider`, `NotifierProvider`, or `.family` providers.
- **CRITICAL**: Modifying operations (insert/update/delete) in DAOs do **NOT** auto-cascade to watching providers. You MUST explicitly call `ref.invalidate()` on **all** affected providers after any database mutation:
  ```dart
  // Example after saving a transaction:
  ref.invalidate(accountsProvider);
  ref.invalidate(accountBalanceProvider(accountId));
  ref.invalidate(todayTransactionsProvider);
  ref.invalidate(allTransactionsProvider);
  ref.invalidate(totalEquityByCurrencyProvider);
  ```

### 2. Balance Model & Single Source of Truth
- **Initial Balance**: `Account.initialBalance` records the opening balance when an account is added.
- **Computed Live Balance**: Current balance is calculated dynamically via `AccountDao.getCurrentBalance(accountId)`:
  $$\text{Current Balance} = \text{Initial Balance} + \sum (\text{Transactions for Account})$$
- Never mutate `accounts.balance` arbitrarily without corresponding transaction records. `transactions` is the immutable source of truth.

### 3. Automated Interest Calculation Rules
- **Formula**: $\text{Daily Gross Interest} = \text{Closing Balance} \times (\text{Annual Rate} / 365.0)$.
- **Withholding Tax**: Default 20% Philippine withholding tax (`0.20`) deducted automatically:
  $$\text{Tax} = \text{Gross Interest} \times 0.20 \quad \implies \quad \text{Net Interest} = \text{Gross Interest} - \text{Tax}$$
- **Tiered Rates**: Handle balance caps (e.g. DiskarTech's ₱50k tier cap) using `InterestEngine.calculateDailyInterest()`.
- **Posting**: Interest payouts generated by `InterestPostingWorker` must be inserted as transactions tagged `type: 'interest'` linked to the system category `'Interest Income'`.

### 4. Inter-Account Transfers
- Inter-account transfers must be executed atomically using `TransactionDao.executeTransfer()`.
- Validate source account balance prior to execution and throw `InsufficientBalanceException` if funds are insufficient.

### 5. Multi-Currency Isolation
- Accounts record their individual ISO 4217 currency code (`PHP`, `USD`, `EUR`).
- Net worth totals must be calculated and displayed grouped by currency (`totalEquityByCurrencyProvider`). Never sum balances across different currencies without explicit exchange rate conversion.

---

## Database & SQLite Constraints

- **WAL Mode**: Database connection in `DatabaseHelper.initDb()` must maintain `PRAGMA journal_mode = WAL` and `PRAGMA foreign_keys = ON`.
- **Triggers**: Daily ending balances in `daily_account_snapshots` are maintained automatically via database trigger `trg_update_daily_snapshot_insert`.
- **Views**: Use pre-aggregated views (`v_daily_analytics`, `v_weekly_analytics`, `v_monthly_category_analytics`) for complex analytics queries instead of writing expensive ad-hoc joins in UI widgets.

---

## Testing Guidelines & Standards

- Test files live under `test/`, mirroring `lib/`:
  - `test/unit/models/` — Pure model serialization and immutability tests.
  - `test/unit/data/` — DAO integration tests against `sqflite_common_ffi`.
  - `test/unit/controllers/` — Provider state & invalidation tests.
  - `test/unit/services/` — Business engine calculation tests (`interest_engine_test.dart`, `github_update_service_test.dart`).
  - `test/widget/` — UI component tests.

### Database Test Isolation Rule
- Every DAO test file's `setUpAll()` **MUST** delete the on-disk test database prior to execution:
  ```dart
  import 'package:path/path.dart' as p;
  
  final path = p.join(await databaseFactory.getDatabasesPath(), 'pitaka.db');
  await databaseFactory.deleteDatabase(path);
  ```
  *(Always import `package:path/path.dart as p` with a prefix to prevent collision with matcher's `equals()` function).*

---

## Developer Commands

```bash
# Run all tests
flutter test

# Run a specific test suite
flutter test test/unit/services/interest_engine_test.dart

# Analyze code for lints
flutter analyze

# Build debug APK
flutter build apk --debug
```

---

## UI & Design System Guidelines

- **Theme**: Always consume design tokens from `AppTheme` (`AppTheme.darkTheme`).
- **Formatting**: Always format money amounts using `CurrencyFormatter.formatMoney(amount, currency)`.
- **Icons**: Use string keys mapped via `CategoryIcons` and financial institution icons via `InstitutionRegistry`.
- **Notch Toast**: Use `AnimatedToast` for in-app floating notifications designed for Android punch-hole notches.
