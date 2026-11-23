// lib/features/transaction/controllers/transaction_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pitaka/features/transaction/data/transaction_dao.dart';
import 'package:pitaka/features/transaction/models/transaction_model.dart';
import 'package:pitaka/features/account/controllers/account_providers.dart';

final transactionDaoProvider = Provider<TransactionDao>((ref) {
  return TransactionDao();
});

class TransactionsController extends AsyncNotifier<List<TransactionModel>> {
  @override
  Future<List<TransactionModel>> build() async {
    final dao = ref.watch(transactionDaoProvider);
    return dao.getAllTransactions();
  }

  Future<void> addTransaction(TransactionModel transaction) async {
    state = AsyncLoading<List<TransactionModel>>().copyWithPrevious(state);
    state = await AsyncValue.guard(() async {
      final dao = ref.read(transactionDaoProvider);
      await dao.insertTransaction(transaction);
      _invalidateRelatedProviders(transaction.accountId);
      return dao.getAllTransactions();
    });
  }

  Future<void> transfer({
    required TransactionModel expense,
    required TransactionModel income,
  }) async {
    state = AsyncLoading<List<TransactionModel>>().copyWithPrevious(state);
    state = await AsyncValue.guard(() async {
      final dao = ref.read(transactionDaoProvider);
      await dao.transferFunds(expense, income);
      _invalidateRelatedProviders(expense.accountId);
      _invalidateRelatedProviders(income.accountId);
      ref.invalidate(accountsProvider);
      return dao.getAllTransactions();
    });
  }

  Future<void> updateTransaction(
    TransactionModel transaction, {
    int? previousAccountId,
  }) async {
    state = AsyncLoading<List<TransactionModel>>().copyWithPrevious(state);
    state = await AsyncValue.guard(() async {
      final dao = ref.read(transactionDaoProvider);
      await dao.updateTransaction(transaction);
      _invalidateRelatedProviders(transaction.accountId);
      if (previousAccountId != null &&
          previousAccountId != transaction.accountId) {
        _invalidateRelatedProviders(previousAccountId);
      }
      ref.invalidate(accountsProvider);
      return dao.getAllTransactions();
    });

    final error = state.asError;
    if (error != null) throw error.error;
  }

  Future<void> deleteTransaction(int transactionId, {int? accountId}) async {
    state = AsyncLoading<List<TransactionModel>>().copyWithPrevious(state);
    state = await AsyncValue.guard(() async {
      final dao = ref.read(transactionDaoProvider);
      await dao.deleteTransaction(transactionId);
      if (accountId != null) {
        _invalidateRelatedProviders(accountId);
      }
      ref.invalidate(accountsProvider);
      return dao.getAllTransactions();
    });

    final error = state.asError;
    if (error != null) throw error.error;
  }

  void _invalidateRelatedProviders(int accountId) {
    ref.invalidate(todayTransactionsProvider);
    ref.invalidate(transactionsByAccountProvider(accountId));
    ref.invalidate(accountBalanceProvider(accountId));
    ref.invalidate(totalEquityByCurrencyProvider);
  }
}

final transactionsControllerProvider =
    AsyncNotifierProvider<TransactionsController, List<TransactionModel>>(
      TransactionsController.new,
    );

final allTransactionsProvider = FutureProvider<List<TransactionModel>>((
  ref,
) async {
  return ref.watch(transactionsControllerProvider.future);
});

final transactionsByAccountProvider =
    FutureProvider.family<List<TransactionModel>, int>((ref, accountId) async {
      final dao = ref.watch(transactionDaoProvider);
      return dao.getTransactionsByAccount(accountId);
    });

final todayTransactionsProvider = FutureProvider<List<TransactionModel>>((
  ref,
) async {
  final dao = ref.watch(transactionDaoProvider);
  return dao.getTodayTransactions();
});
