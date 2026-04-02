import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/recovery_plan.dart';

class RecoveryPlanRepository {
  static const String _storageKey = 'support_recovery_plan';

  Future<RecoveryPlan> getPlan() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      return RecoveryPlan.defaults();
    }

    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return RecoveryPlan.fromMap(decoded);
  }

  Future<void> savePlan(RecoveryPlan plan) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(plan.toMap()));
  }
}
