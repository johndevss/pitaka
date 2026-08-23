// lib/providers/daily_limit_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pitaka/features/dashboard/data/daily_limit_dao.dart';
import 'package:pitaka/features/dashboard/models/daily_limit.dart';

final dailyLimitDaoProvider = Provider<DailyLimitDao>((ref) {
  return DailyLimitDao();
});

final currentDailyLimitProvider = FutureProvider<DailyLimit?>((ref) async {
  final dao = ref.watch(dailyLimitDaoProvider);
  return dao.getCurrentDailyLimit();
});
