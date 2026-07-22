// lib/providers/transaction_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/transaction_dao.dart';
import '../models/transaction_model.dart';

final transactionDaoProvider = Provider<TransactionDao>((ref) {
  return TransactionDao();
});

final allTransactionsProvider = FutureProvider<List<TransactionModel>>((
  ref,
) async {
  final dao = ref.watch(transactionDaoProvider);
  return dao.getAllTransactions();
});

final transactionsByAccountProvider =
    FutureProvider.family<List<TransactionModel>, int>((ref, accountId) async {
      ref.watch(allTransactionsProvider);

      final dao = ref.watch(transactionDaoProvider);
      return dao.getTransactionsByAccount(accountId);
    });

final todayTransactionsProvider = FutureProvider<List<TransactionModel>>((
  ref,
) async {
  final dao = ref.watch(transactionDaoProvider);
  return dao.getTodayTransactions();
});
