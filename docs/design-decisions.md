# Architectural & Feature Design Decisions

This document details the core design decisions made throughout Pitaka's development, explaining the rationale behind key technical choices.

---

## 1. Computed Balance & Stored Balance Model

### Problem
In financial applications, storing only a mutable `balance` field can cause transaction history and reported account balances to drift out of sync if an update fails or is missed.

### Decision
`Account.initialBalance` records the opening balance when an account is created. The live current balance is derived dynamically in `AccountDao.getCurrentBalance()`:

$$\text{Current Balance} = \text{Initial Balance} + \sum (\text{Transactions for Account})$$

In addition, `accounts.balance` is updated via single-pass SQL queries, and `daily_account_snapshots` records ending daily balances automatically via SQLite trigger (`trg_update_daily_snapshot_insert`). Transaction records remain the immutable single source of truth.

---

## 2. Automated Bank Interest Engine & Daily Accrual

### Context
Philippine high-yield digital banks and e-wallets (SeaBank, Maya, GoTyme, DiskarTech, etc.) pay interest daily or monthly, subject to a 20% Philippine withholding tax on interest earnings.

### Design
1. **`InterestEngine`**: Pure math logic calculating daily gross interest ($R_{\text{annual}} / 365$), deducting 20% tax ($T = 0.20 \times \text{Gross}$), applying balance caps (e.g. DiskarTech's ₱50k cap), and producing net interest ($I_{\text{net}} = \text{Gross} - T$).
2. **`InterestLedgerDao`**: Stores daily unposted accruals in `interest_ledger`.
3. **`InterestPostingWorker`**: Checks missed accrual days on app open, updates the ledger, and auto-posts a payout transaction tagged `type: 'interest'` linked to system category `'Interest Income'` once payout frequency thresholds (`daily` or `monthly` day) are met.

---

## 3. Inter-Account Transfers

### Problem
Transferring money between two accounts (e.g. BDO to GCash) requires deducting from one account and crediting another without corrupting balances if an error occurs mid-operation.

### Decision
Transfers are executed atomically in `TransactionDao.executeTransfer()` within a single SQLite transaction:
- Validates source account balance (`InsufficientBalanceException` thrown if insufficient).
- Inserts an outgoing transaction tagged `type: 'transfer'` linking `destination_account_id`.
- Atomically updates source and destination balances.

---

## 4. Multi-Currency Isolation

### Context
Users may hold accounts denominated in PHP, USD, or EUR. Without live exchange rates, summing amounts across currencies produces inaccurate net worth totals.

### Decision
- Accounts record their ISO currency code (`accounts.currency`).
- Totals are calculated and presented grouped by currency (`totalEquityByCurrencyProvider`).
- Net worth is never arbitrarily summed across different currencies.

---

## 5. Category Relational Cascade

### Context
Deleting a category should not erase past transaction records associated with that category name.

### Decision
- `categories` table stores `id`, `name`, `icon_key`, `color_hex`, and `is_system` (for protected categories like Interest Income).
- `transactions.category_id` references `categories.id` with `ON DELETE SET NULL`.
- `transactions.category` maintains a string fallback, ensuring past transaction history remains preserved even if a category row is deleted.

---

## 6. In-App GitHub Release Updater

### Decision
To keep users updated without relying on Google Play Services or centralized app stores, `GithubUpdateService` queries GitHub's REST API for latest release tags, compares versions via `package_info_plus`, and `ApkUpdateService` downloads and installs APK binaries natively with progress feedback.
