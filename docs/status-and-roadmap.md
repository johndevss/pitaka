# Status, Roadmap & Non-Goals

---

## Current Completed Features

- [x] Feature-First Clean Architecture refactoring (`lib/core` & `lib/features/`)
- [x] SQLite schema version 1 with WAL mode, foreign keys, daily balance snapshot trigger, and analytics views
- [x] Institution Registry (`InstitutionRegistry`) supporting Philippine banks & e-wallets (SeaBank, Maya, GoTyme, GCash, BDO, BPI, CIMB, Tonik, Maribank)
- [x] Multi-currency account support (PHP, USD, EUR, etc.) with net worth totals grouped per currency
- [x] Bank & E-wallet Automated Interest Engine (`InterestEngine`), Daily Ledger DAO (`InterestLedgerDao`), and Interest Posting Worker (`InterestPostingWorker`)
- [x] 20% Philippine withholding tax calculation, daily accrual logging, tiered rate caps, and auto-posted interest transactions
- [x] Accounts management (Add, Edit, Archive, live balance calculation, interest rate badges)
- [x] Transactions system (Expense, Income, atomic Inter-Account Transfers with insufficient balance guards)
- [x] Categories management with expense/income tabs and system category protection
- [x] History Screen with date grouping, search filters, and transaction details
- [x] Daily spending limit tracking (`DailyLimitDao`, `DailyLimitProviders`)
- [x] Dynamic Island notch toast system (`AnimatedToast`) and custom application theme (`AppTheme`)
- [x] In-app GitHub APK release update checker (`GithubUpdateService`, `ApkUpdateService`, `UpdateDialog`)
- [x] Asset precaching and state pre-warming for startup optimization
- [x] 78 automated unit, DAO, controller, service, and widget tests passing

---

## Planned Roadmap

- [ ] **Budgeting Engine & Visual Dashboard** — Category budget tracking using the `budgets` table and charts using analytics views (`v_daily_analytics`, `v_monthly_category_analytics`).
- [ ] **Data Export & Backup / Restore** — CSV export and encrypted SQLite database backup/restore.
- [ ] **Recurring Transactions / Scheduled Payments** — Automated recording of recurring bills and subscriptions.
- [ ] **Custom Institution Interest Customizer** — UI modal allowing custom institution rate tiers and schedules.
- [ ] **CI/CD Pipeline** — GitHub Actions workflow for automated testing (`flutter test`) and APK release packaging.

---

## Non-Goals (for now)

- **No forced cloud sync or external servers**: Data is stored local-only for complete privacy.
- **No third-party bank scraping or API credential storage**: Manual entry and automated local calculation only.
- **No arbitrary exchange-rate currency conversion**: Net worth per currency is displayed distinctly to maintain financial precision without real-time exchange rates.
