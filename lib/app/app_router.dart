import 'package:flutter/material.dart';

import '../core/constants/route_names.dart';
import '../features/cycle/domain/cycle_stage.dart';
import '../features/cycle/presentation/cycle_screen.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/insights/presentation/insights_screen.dart';
import '../features/log/presentation/cycle_stage_log_screen.dart';
import '../features/log/presentation/log_hub_screen.dart';
import '../features/privacy/domain/lock_scope.dart';
import '../features/privacy/domain/lock_settings.dart';
import '../features/privacy/presentation/lock_gate_screen.dart';
import '../features/rescue/presentation/rescue_screen.dart';
import '../features/support/presentation/support_screen.dart';

class AppRouter {
  static final LockSettings _lockSettings = LockSettings.disabled();

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case RouteNames.home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case RouteNames.rescue:
        return MaterialPageRoute(builder: (_) => const RescueScreen());
      case RouteNames.cycle:
        return MaterialPageRoute(
          builder: (_) => _protect(
            scope: LockScope.cycle,
            child: const CycleScreen(),
          ),
        );
      case RouteNames.logHub:
        return MaterialPageRoute(
          builder: (_) => _protect(
            scope: LockScope.logs,
            child: const LogHubScreen(),
          ),
        );
      case RouteNames.cycleStageLog:
        final stage = settings.arguments is CycleStage
            ? settings.arguments as CycleStage
            : CycleStage.triggers;
        return MaterialPageRoute(
          builder: (_) => _protect(
            scope: LockScope.logs,
            child: CycleStageLogScreen(initialStage: stage),
          ),
        );
      case RouteNames.insights:
        return MaterialPageRoute(
          builder: (_) => _protect(
            scope: LockScope.insights,
            child: const InsightsScreen(),
          ),
        );
      case RouteNames.support:
        return MaterialPageRoute(builder: (_) => const SupportScreen());
      default:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
    }
  }

  static Widget _protect({
    required LockScope scope,
    required Widget child,
  }) {
    final shouldLock = _lockSettings.shouldLock(scope);
    if (!shouldLock) {
      return child;
    }

    return LockGateScreen(
      title: 'Protected Content',
      subtitle: 'Unlock to continue.',
      onUnlockSuccess: () {},
    );
  }
}
