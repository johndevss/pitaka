# Architecture Overview

Pitaka is a local-first Flutter application — there is no backend server or external API dependency. Data lives entirely in an embedded SQLite database on the device, configured with Write-Ahead Logging (WAL) mode and foreign key enforcement for high performance and data integrity.

---

## Architectural Pattern

The codebase is organized around **Feature-First Clean Architecture**:

```
UI (Screens / Widgets)
   ↕  watches / reads
Controllers (Riverpod Providers)
   ↕  calls
Services / Workers (e.g. InterestPostingWorker, InterestEngine, UpdateService)
   ↕  calls
DAOs (Data Access Objects)
   ↕  reads / writes
SQLite Database (via sqflite + WAL mode)
```

---

## Codebase Organization

The source code in `lib/` is split into two primary areas:

### 1. Core Infrastructure (`lib/core/`)
Holds cross-cutting concerns, shared UI components, design tokens, database setup, and global services used across multiple features:

- **`database/`**: Database connection initialization, schema definitions, migrations, triggers, and views (`DatabaseHelper`).
- **`providers/`**: Global application providers (e.g. app updater state).
- **`services/`**: Infrastructure services (`GithubUpdateService`, `ApkUpdateService`).
- **`theme/`**: Central visual design system tokens (`AppTheme`).
- **`utils/`**: Shared utilities (`currency_formatter.dart`, `category_icons.dart`, `page_transitions.dart`).
- **`widgets/`**: Reusable custom widgets (`NumericKeypad`, `AnimatedToast`, `FloatingNavBar`, `TransactionTile`, `InterestTypeSelector`, `SharedAxisTabSwitcher`).

### 2. Feature Modules (`lib/features/`)
Self-contained domain directories (`account`, `category`, `dashboard`, `transaction`). Each feature module follows the same sub-structure:

- **`models/`**: Immutable Dart classes representing domain entities and view models.
- **`data/`**: Data Access Objects (DAOs) and static registries interacting directly with SQLite.
- **`services/`**: Feature-specific business logic engines and background workers.
- **`controllers/`**: Riverpod providers bridging DAOs/services to presentation state.
- **`presentation/`**: Flutter UI components (`ConsumerWidget` / `ConsumerStatefulWidget`), screens, dialogs, and cards.

---

## State Management Flow (Riverpod)

Pitaka uses **Flutter Riverpod** (`flutter_riverpod`) for reactive state management:

1. **Provider Exposure**: DAOs and async data calls are exposed through Riverpod providers (`FutureProvider`, `NotifierProvider`, `.family`).
2. **UI Subscription**: Screens watch providers using `ref.watch()`. When provider state updates, subscribed widgets automatically rebuild.
3. **Explicit Invalidation**: Modifying operations (insert/update/delete) trigger manual invalidation on affected providers (`ref.invalidate()`). For example, saving a transaction invalidates `accountsProvider`, `accountBalanceProvider(id)`, `todayTransactionsProvider`, `allTransactionsProvider`, and `totalEquityByCurrencyProvider`.
