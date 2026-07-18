// lib/providers/daily_limit_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/daily_limit_dao.dart';
import '../models/daily_limit.dart';

final dailyLimitDaoProvider = Provider<DailyLimitDao>((ref) {
  return DailyLimitDao();
});

final currentDailyLimitProvider = FutureProvider<DailyLimit?>((ref) async {
  final dao = ref.watch(dailyLimitDaoProvider);
  return dao.getCurrentDailyLimit();
});