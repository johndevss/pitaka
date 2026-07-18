// lib/providers/account_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/account_dao.dart';
import '../models/account.dart';

final accountDaoProvider = Provider<AccountDao>((ref) {
  return AccountDao();
});

final accountsProvider = FutureProvider<List<Account>>((ref) async {
  final dao = ref.watch(accountDaoProvider);
  return dao.getAllAccounts();
});

// Computed balance for a single account (starting balance + all transactions)
final accountBalanceProvider = FutureProvider.family<double, int>((ref, accountId) async {
  final dao = ref.watch(accountDaoProvider);
  return dao.getCurrentBalance(accountId);
});