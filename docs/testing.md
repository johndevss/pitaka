# Testing Strategy & Execution

Pitaka maintains a comprehensive test suite under `test/`, structured to mirror `lib/`.

---

## Test Directory Layout

```
test/
├── unit/
│   ├── controllers/
│   │   ├── accounts_controller_test.dart
│   │   └── transactions_controller_test.dart
│   ├── data/
│   │   ├── account_dao_test.dart
│   │   ├── category_dao_test.dart
│   │   ├── daily_limit_dao_test.dart
│   │   └── transaction_dao_test.dart
│   ├── database/
│   │   └── database_helper_test.dart
│   ├── models/
│   │   ├── account_test.dart
│   │   ├── category_test.dart
│   │   ├── daily_limit_test.dart
│   │   ├── institution_test.dart
│   │   └── transaction_model_test.dart
│   ├── services/
│   │   ├── github_update_service_test.dart
│   │   └── interest_engine_test.dart
│   └── utils/
│       └── currency_formatter_test.dart
└── widget/
    ├── app_smoke_test.dart
    ├── floating_nav_bar_test.dart
    ├── interest_type_selector_test.dart
    ├── numeric_keypad_test.dart
    └── update_dialog_test.dart
```

---

## Running Tests

Execute the full automated test suite using the Flutter test runner:

```bash
flutter test
```

To run a specific test suite:

```bash
flutter test test/unit/services/interest_engine_test.dart
```

---

## DAO & Database Test Isolation

DAO unit tests execute against an on-disk SQLite database via `sqflite_common_ffi`.

To prevent state leakage and schema mismatch across test runs, every DAO test file's `setUpAll()` explicitly resets the database file:

```dart
final path = p.join(await databaseFactory.getDatabasesPath(), 'pitaka.db');
await databaseFactory.deleteDatabase(path);
```

*(Note: `package:path/path.dart` is imported with prefix `as p` to avoid collision with matcher's `equals()` function).*

---

## Test Suite Summary

- **`interest_engine_test.dart`**: Tests daily gross interest calculation, 20% withholding tax calculation, DiskarTech tiered balance caps, multi-day missed calculations, and interest payout posting.
- **`github_update_service_test.dart`**: Tests semantic release version parsing, `v` prefix handling, asset extraction, and version comparisons.
- **`account_dao_test.dart` & `transaction_dao_test.dart`**: Test CRUD operations, single-pass computed balance queries, transfers, and invalid balance exceptions.
- **`accounts_controller_test.dart` & `transactions_controller_test.dart`**: Test Riverpod provider state changes and invalidation chains.
- **Widget Tests**: Test visual component rendering and user interaction (`floating_nav_bar_test.dart`, `numeric_keypad_test.dart`, `interest_type_selector_test.dart`, `update_dialog_test.dart`, `app_smoke_test.dart`).
