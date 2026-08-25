# Pitaka — Documentation Index

Welcome to the **Pitaka** project documentation. This documentation is organized into focused sub-documents for easier navigation and maintenance.

---

## Documentation Sections

| Document | Description |
| --- | --- |
| 🏗️ **[Architecture](architecture.md)** | High-level system architecture, Feature-First Clean Architecture layout, layer responsibilities, and Riverpod state management flow. |
| 📁 **[File Structure](file-structure.md)** | Complete directory tree and detailed file-by-file reference for `lib/` and `test/`. |
| 🗄️ **[Database & Schema](database-schema.md)** | Embedded SQLite setup, WAL mode, table DDLs, indexes, database triggers, and pre-aggregated analytics views. |
| 💡 **[Design Decisions](design-decisions.md)** | Architectural rationale for computed balances, automated interest calculation engine, inter-account transfers, multi-currency isolation, and updater system. |
| 🧪 **[Testing](testing.md)** | Automated test suite structure, unit/DAO/controller/widget test coverage, database test isolation, and commands. |
| 🎯 **[Status & Roadmap](status-and-roadmap.md)** | Current feature completion checklist, planned roadmap, and project non-goals. |

---

## Overview

Pitaka is a local-first, open-source personal finance tracker for Flutter (Android/iOS) built specifically for managing Philippine bank accounts, e-wallets, credit lines, and cash.

Data lives entirely in an embedded SQLite database on the user's device. There is no backend server, cloud sync, or external tracking.

---

## Quick Links

- [Root README](../README.md)
- [Architecture Overview](architecture.md)
- [Database Schema](database-schema.md)
- [Testing Guide](testing.md)
