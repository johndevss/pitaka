# File Structure & Reference

This document maps out all files in the Pitaka codebase across `lib/` and `test/`, detailing the responsibility of each file.

---

## Directory Layout

```
lib/
├── main.dart
├── core/
│   ├── database/
│   │   └── database_helper.dart
│   ├── providers/
│   │   └── update_provider.dart
│   ├── services/
│   │   ├── apk_update_service.dart
│   │   └── github_update_service.dart
│   ├── theme/
│   │   └── app_theme.dart
│   ├── utils/
│   │   ├── category_icons.dart
│   │   ├── currency_formatter.dart
│   │   └── page_transitions.dart
│   └── widgets/
│       ├── animated_toast.dart
│       ├── floating_nav_bar.dart
│       ├── interest_type_selector.dart
│       ├── numeric_keypad.dart
│       ├── shared_axis_tab_switcher.dart
│       ├── transaction_tile.dart
│       └── widgets.dart
└── features/
    ├── account/
    │   ├── controllers/
    │   │   └── account_providers.dart
    │   ├── data/
    │   │   ├── account_dao.dart
    │   │   ├── institutions.dart
    │   │   └── interest_ledger_dao.dart
    │   ├── models/
    │   │   ├── account.dart
    │   │   ├── account_interest_config.dart
    │   │   └── institution.dart
    │   ├── presentation/
    │   │   ├── accounts_screen.dart
    │   │   ├── add_account_screen.dart
    │   │   ├── edit_account_screen.dart
    │   │   └── widgets/
    │   │       └── account_card.dart
    │   └── services/
    │       ├── interest_engine.dart
    │       └── interest_posting_worker.dart
    ├── category/
    │   ├── controllers/
    │   │   └── category_providers.dart
    │   ├── data/
    │   │   └── category_dao.dart
    │   ├── models/
    │   │   └── category.dart
    │   └── presentation/
    │       ├── categories_screen.dart
    │       └── manage_screen.dart
    ├── dashboard/
    │   ├── controllers/
    │   │   └── daily_limit_providers.dart
    │   ├── data/
    │   │   └── daily_limit_dao.dart
    │   ├── models/
    │   │   └── daily_limit.dart
    │   └── presentation/
    │       ├── dashboard_screen.dart
    │       ├── home_shell.dart
    │       └── widgets/
    │           └── update_dialog.dart
    └── transaction/
        ├── controllers/
        │   └── transaction_providers.dart
        ├── data/
        │   └── transaction_dao.dart
        ├── models/
        │   └── transaction_model.dart
        └── presentation/
            ├── expense_screen.dart
            ├── history_screen.dart
            └── transfer_screen.dart
```

---

## Detailed File Reference

### App Entry Point

- **`lib/main.dart`**: Entry point. Wraps app in Riverpod `ProviderScope`, initializes `AppTheme.darkTheme`, pre-warms asset caches, and mounts `HomeShell`.

### Core Layer (`lib/core/`)

- **`database/database_helper.dart`**: Database lifecycle manager, SQLite configuration (WAL mode, foreign keys, synchronous NORMAL), tables DDL, database triggers, analytics views, and institution/category seeders.
- **`services/github_update_service.dart`**: Fetches GitHub releases via REST API, compares version tags against current app version (`package_info_plus`), and checks for APK release assets.
- **`services/apk_update_service.dart`**: Downloads release APKs asynchronously with download progress reporting and triggers native Android package installer intents.
- **`providers/update_provider.dart`**: `checkForUpdateProvider` exposing update availability to the UI on launch.
- **`theme/app_theme.dart`**: Central theme constants, typography, dark mode properties, color system, and card styles.
- **`utils/currency_formatter.dart`**: Pure functions (`formatMoney`, `currencySymbol`) backed by `intl` for locale-aware currency rendering across any ISO code.
- **`utils/category_icons.dart`**: Lookups converting icon strings to `IconData`, hex strings to `Color`, and color palette definitions.
- **`utils/page_transitions.dart`**: Custom route transition animations (`SmoothExpandRoute`).
- **`widgets/animated_toast.dart`**: Dynamic Island-inspired notch toast notification with morphing physics for punch-hole screens.
- **`widgets/floating_nav_bar.dart`**: Floating bottom nav bar with animated tab switching and quick-action menu button.
- **`widgets/numeric_keypad.dart`**: Touch keypad for transaction input with decimal and backspace handling.
- **`widgets/interest_type_selector.dart`**: Custom chip selector for interest calculation modes and payout schedules.
- **`widgets/shared_axis_tab_switcher.dart`**: Material Shared Axis tab transition container.
- **`widgets/transaction_tile.dart`**: Standardized transaction tile showing category icon, account details, formatted amounts, and tax/interest badges.

### Account Feature (`lib/features/account/`)

- **`models/account.dart`**: Account domain model storing starting balance (`initialBalance`), computed live balance (`currentBalance`), accrued interest (`pendingInterest`), ISO currency, and archiving status.
- **`models/account_interest_config.dart`**: Interest configuration model containing annual APR, calculation mode, payout frequency, 20% withholding tax rate, tier caps, and auto-post settings.
- **`models/institution.dart`**: Profile model for predefined financial institutions.
- **`data/account_dao.dart`**: DAO for `accounts` and `account_interest_configs` CRUD and single-pass live balance calculation.
- **`data/institutions.dart`**: `InstitutionRegistry` spec holding profiles for Philippine banks and e-wallets (SeaBank, Maya, GoTyme, GCash, BDO, BPI, Tonik, Maribank).
- **`data/interest_ledger_dao.dart`**: DAO for logging and posting entries in `interest_ledger`.
- **`services/interest_engine.dart`**: Pure math engine computing daily interest, 20% PH tax deduction, net interest, tiered balance caps, and multi-day missed calculations.
- **`services/interest_posting_worker.dart`**: Background engine checking missed interest days on startup, generating ledger entries, and auto-posting interest transactions.
- **`controllers/account_providers.dart`**: Riverpod providers (`accountsProvider`, `accountBalanceProvider`, `totalEquityByCurrencyProvider`, `autoInterestCheckProvider`).
- **`presentation/accounts_screen.dart`**: Net worth header, account grid, archive toggle, and account creation trigger.
- **`presentation/add_account_screen.dart`**: Tabbed creation form (Wallet / Savings / Credit) with institution auto-fill and interest setup.
- **`presentation/edit_account_screen.dart`**: Form for modifying existing account settings, interest configs, or archiving status.
- **`presentation/widgets/account_card.dart`**: Summary card rendering live balance, institution logo, currency symbol, interest badges, and pending earnings.

### Category Feature (`lib/features/category/`)

- **`models/category.dart`**: Category entity storing name, icon, color hex, parent ID, and system flag (`isSystem`).
- **`data/category_dao.dart`**: DAO managing `categories` CRUD.
- **`controllers/category_providers.dart`**: `categoriesProvider` and `categoriesByTypeProvider(type)`.
- **`presentation/categories_screen.dart`**: Tabbed category manager (Expense / Income) with custom category creator bottom sheet.
- **`presentation/manage_screen.dart`**: Settings and categories overview screen.

### Dashboard Feature (`lib/features/dashboard/`)

- **`models/daily_limit.dart`**: Daily limit model representing spending caps.
- **`data/daily_limit_dao.dart`**: DAO for managing daily spending caps.
- **`controllers/daily_limit_providers.dart`**: `currentDailyLimitProvider`.
- **`presentation/dashboard_screen.dart`**: Home screen with currency-grouped total equity banner, account carousel, daily limit progress, and recent transaction feed.
- **`presentation/home_shell.dart`**: Navigation shell housing bottom bar, action triggers, update dialog check, and interest auto-posting check.
- **`presentation/widgets/update_dialog.dart`**: Update prompt dialog rendering markdown release notes and progress bar.

### Transaction Feature (`lib/features/transaction/`)

- **`models/transaction_model.dart`**: Transaction model supporting `expense`, `income`, `transfer`, and `interest` types, tax breakdown (`grossAmount`, `taxAmount`), notes, and dates.
- **`data/transaction_dao.dart`**: DAO for transactions CRUD, atomic transfers (`executeTransfer`), and date filters (`getTodayTransactions`).
- **`controllers/transaction_providers.dart`**: Providers for transactions (`allTransactionsProvider`, `groupedTransactionsProvider`, `dailySpendingTotalProvider`).
- **`presentation/expense_screen.dart`**: Expense and Income entry keypad with category selector, account selector, and provider invalidation.
- **`presentation/transfer_screen.dart`**: Inter-account transfer screen supporting source/destination selection and balance validation.
- **`presentation/history_screen.dart`**: Complete transaction log with search filter and account filters.
