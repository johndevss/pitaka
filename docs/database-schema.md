# Database Architecture & Schema

Pitaka uses an embedded SQLite database (`pitaka.db`) managed via `sqflite`. The database runs at schema version 1 with foreign key constraints enabled, Write-Ahead Logging (`WAL`) mode, and synchronous mode set to `NORMAL`.

---

## Connection & PRAGMA Configuration

Every database connection in `DatabaseHelper.initDb()` applies the following PRAGMAs:

```sql
PRAGMA foreign_keys = ON;
PRAGMA journal_mode = WAL;
PRAGMA synchronous = NORMAL;
PRAGMA cache_size = -64000;
PRAGMA temp_store = MEMORY;
```

- **WAL Mode (`journal_mode = WAL`)**: Allows concurrent reads while writes are occurring, eliminating main-thread UI jank.
- **Foreign Keys (`foreign_keys = ON`)**: Enforces relational data integrity across tables (e.g. cascading deletes for interest configs and ledger entries).

---

## Schema DDL (Tables)

### 1. `institutions`
Predefined profiles for supported Philippine banks and e-wallets.

```sql
CREATE TABLE institutions (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  type TEXT NOT NULL,
  icon_key TEXT NOT NULL,
  default_currency TEXT NOT NULL DEFAULT 'PHP',
  has_interest INTEGER NOT NULL DEFAULT 0
);
```

### 2. `accounts`
Financial accounts (bank, e-wallet, credit, cash).

```sql
CREATE TABLE accounts (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  institution_id TEXT,
  account_type TEXT NOT NULL DEFAULT 'bank',
  type TEXT,
  provider TEXT,
  initial_balance REAL NOT NULL DEFAULT 0.0,
  balance REAL NOT NULL DEFAULT 0.0,
  currency TEXT NOT NULL DEFAULT 'PHP',
  interest_rate REAL,
  interest_type TEXT NOT NULL DEFAULT 'none',
  last_interest_applied_date TEXT,
  color_hex TEXT,
  icon_key TEXT,
  is_archived INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (institution_id) REFERENCES institutions (id) ON DELETE SET NULL
);
```

### 3. `account_interest_configs`
Detailed interest rate and payout rules for high-yield accounts.

```sql
CREATE TABLE account_interest_configs (
  account_id INTEGER PRIMARY KEY,
  interest_rate REAL NOT NULL,
  calc_mode TEXT NOT NULL DEFAULT 'daily_accrue',
  payout_frequency TEXT NOT NULL DEFAULT 'monthly',
  payout_day INTEGER NOT NULL DEFAULT 1,
  withholding_tax_rate REAL NOT NULL DEFAULT 0.20,
  tier_cap_amount REAL,
  secondary_interest_rate REAL,
  auto_post INTEGER NOT NULL DEFAULT 1,
  last_interest_applied_date TEXT,
  FOREIGN KEY (account_id) REFERENCES accounts (id) ON DELETE CASCADE
);
```

### 4. `categories`
Transaction categories supporting hierarchy and system category flags.

```sql
CREATE TABLE categories (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  type TEXT NOT NULL,
  icon_key TEXT NOT NULL,
  color_hex TEXT NOT NULL,
  parent_id INTEGER,
  is_system INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (parent_id) REFERENCES categories (id) ON DELETE CASCADE
);
```

### 5. `transactions`
Income, expense, transfer, and interest transaction entries.

```sql
CREATE TABLE transactions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  account_id INTEGER NOT NULL,
  type TEXT NOT NULL DEFAULT 'expense',
  amount REAL NOT NULL,
  category TEXT,
  category_id INTEGER,
  destination_account_id INTEGER,
  gross_amount REAL,
  tax_amount REAL,
  note TEXT,
  transaction_date TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (account_id) REFERENCES accounts (id) ON DELETE CASCADE,
  FOREIGN KEY (destination_account_id) REFERENCES accounts (id) ON DELETE SET NULL,
  FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE SET NULL
);
```

### 6. `interest_ledger`
Daily accrued interest log entries prior to payout posting.

```sql
CREATE TABLE interest_ledger (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  account_id INTEGER NOT NULL,
  date TEXT NOT NULL,
  closing_balance REAL NOT NULL,
  gross_interest REAL NOT NULL,
  tax_deducted REAL NOT NULL,
  net_interest REAL NOT NULL,
  is_posted INTEGER NOT NULL DEFAULT 0,
  FOREIGN KEY (account_id) REFERENCES accounts (id) ON DELETE CASCADE
);
```

### 7. `budgets` & `daily_limits`
Category spending budgets and global daily spending limits.

```sql
CREATE TABLE budgets (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  category_id INTEGER,
  amount REAL NOT NULL,
  period TEXT NOT NULL DEFAULT 'daily',
  effective_date TEXT NOT NULL,
  FOREIGN KEY (category_id) REFERENCES categories (id) ON DELETE CASCADE
);

CREATE TABLE daily_limits (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  amount REAL NOT NULL,
  effective_date TEXT NOT NULL
);
```

### 8. `daily_account_snapshots`
Cached ending balance per account per day.

```sql
CREATE TABLE daily_account_snapshots (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  account_id INTEGER NOT NULL,
  snapshot_date TEXT NOT NULL,
  ending_balance REAL NOT NULL,
  created_at TEXT NOT NULL DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (account_id) REFERENCES accounts (id) ON DELETE CASCADE,
  UNIQUE(account_id, snapshot_date)
);
```

---

## Database Triggers

- **`trg_update_daily_snapshot_insert`**: Fires automatically after a transaction is inserted to update `daily_account_snapshots` for the transaction's account and date:

```sql
CREATE TRIGGER trg_update_daily_snapshot_insert
AFTER INSERT ON transactions
BEGIN
  INSERT INTO daily_account_snapshots (account_id, snapshot_date, ending_balance)
  VALUES (
    NEW.account_id, 
    DATE(NEW.transaction_date),
    (SELECT initial_balance FROM accounts WHERE id = NEW.account_id) + 
    (SELECT COALESCE(SUM(amount), 0) FROM transactions WHERE account_id = NEW.account_id AND DATE(transaction_date) <= DATE(NEW.transaction_date))
  )
  ON CONFLICT(account_id, snapshot_date) DO UPDATE SET
    ending_balance = excluded.ending_balance;
END;
```

---

## Indexes & Views

### Indexes
- `idx_tx_date`: `transactions (transaction_date)`
- `idx_tx_type_date`: `transactions (type, transaction_date)`
- `idx_tx_cat_date`: `transactions (category_id, transaction_date)`
- `idx_tx_account_date`: `transactions (account_id, transaction_date)`
- `idx_snapshots_date`: `daily_account_snapshots (snapshot_date)`

### Pre-Aggregated Views
- **`v_daily_analytics`**: Aggregates total income, expense, interest earned, and net cashflow grouped by `DATE(transaction_date)`.
- **`v_weekly_analytics`**: Aggregates totals by ISO year-week (`STRFTIME('%Y-%W')`).
- **`v_monthly_category_analytics`**: Aggregates totals and counts by category and type per month (`STRFTIME('%Y-%m')`).
