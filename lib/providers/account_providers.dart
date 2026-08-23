// lib/providers/account_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/account_dao.dart';
import '../models/account.dart';

final accountDaoProvider = Provider<AccountDao>((ref) {
  return AccountDao();
});

class AccountsController extends AsyncNotifier<List<Account>> {
  @override
  Future<List<Account>> build() async {
    final dao = ref.watch(accountDaoProvider);
    return dao.getAllAccounts();
  }

  Future<void> addAccount(Account account) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final dao = ref.read(accountDaoProvider);
      await dao.insertAccount(account);
      ref.invalidate(totalEquityByCurrencyProvider);
      return dao.getAllAccounts();
    });
  }

  Future<void> updateAccount(Account account) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final dao = ref.read(accountDaoProvider);
      await dao.updateAccount(account);
      if (account.id != null) {
        ref.invalidate(accountBalanceProvider(account.id!));
      }
      ref.invalidate(totalEquityByCurrencyProvider);
      return dao.getAllAccounts();
    });
  }

  Future<void> deleteAccount(int accountId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final dao = ref.read(accountDaoProvider);
      await dao.deleteAccount(accountId);
      ref.invalidate(totalEquityByCurrencyProvider);
      return dao.getAllAccounts();
    });
  }
}

final accountsControllerProvider =
    AsyncNotifierProvider<AccountsController, List<Account>>(
      AccountsController.new,
    );

final accountsProvider = FutureProvider<List<Account>>((ref) async {
  return ref.watch(accountsControllerProvider.future);
});

// Computed balance for a single account (starting balance + all transactions)
final accountBalanceProvider = FutureProvider.family<double, int>((
  ref,
  accountId,
) async {
  final dao = ref.watch(accountDaoProvider);
  return dao.getCurrentBalance(accountId);
});

final totalEquityByCurrencyProvider = FutureProvider<Map<String, double>>((
  ref,
) async {
  final dao = ref.watch(accountDaoProvider);
  final accounts = await dao.getAllAccounts();

  final Map<String, double> totals = {};
  for (final account in accounts) {
    final balance = await dao.getCurrentBalance(account.id!);
    totals[account.currency] = (totals[account.currency] ?? 0) + balance;
  }
  return totals;
});
