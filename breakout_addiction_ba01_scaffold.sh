#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(pwd)"

echo "==> Creating Breakout Addiction BA-01 scaffold in: $ROOT_DIR"

mkdir -p \
  .github/workflows \
  lib/app/theme \
  lib/core/constants \
  lib/core/widgets \
  lib/features/home/presentation/widgets \
  lib/features/rescue/presentation/widgets \
  lib/features/log/presentation \
  lib/features/insights/presentation \
  lib/features/support/presentation \
  lib/features/privacy/domain \
  lib/features/privacy/presentation \
  test \
  tools

cat > pubspec.yaml <<'EOD'
name: breakout_addiction
description: Android-first recovery app for compulsive pornography use.
publish_to: "none"

version: 0.1.0+1

environment:
  sdk: ">=3.3.0 <4.0.0"

dependencies:
  flutter:
    sdk: flutter

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0

flutter:
  uses-material-design: true
EOD

cat > analysis_options.yaml <<'EOD'
include: package:flutter_lints/flutter.yaml

linter:
  rules:
    prefer_const_constructors: true
    prefer_const_literals_to_create_immutables: true
EOD

cat > .gitignore <<'EOD'
.dart_tool/
.packages
.pub/
build/
.flutter-plugins
.flutter-plugins-dependencies
.metadata
.idea/
android/.gradle/
android/local.properties
ios/Flutter/.last_build_id
*.log
EOD

cat > .github/workflows/ci.yml <<'EOD'
name: CI

on:
  push:
    branches: [ main, master ]
  pull_request:
  workflow_dispatch:

jobs:
  build-android:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Set up Java
        uses: actions/setup-java@v4
        with:
          distribution: temurin
          java-version: '17'

      - name: Set up Flutter
        uses: subosito/flutter-action@v2
        with:
          channel: stable
          cache: true

      - name: Flutter version
        run: flutter --version

      - name: Create platform folders if missing
        run: |
          if [ ! -d android ]; then
            flutter create --platforms=android --project-name breakout_addiction .
          fi

      - name: Get packages
        run: flutter pub get

      - name: Analyze
        run: flutter analyze

      - name: Run tests
        run: flutter test

      - name: Build APK
        run: flutter build apk --release
EOD

cat > lib/main.dart <<'EOD'
import 'package:flutter/material.dart';

import 'app/breakout_app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BreakoutApp());
}
EOD

cat > lib/app/breakout_app.dart <<'EOD'
import 'package:flutter/material.dart';

import '../core/constants/route_names.dart';
import 'app_router.dart';
import 'theme/app_theme.dart';

class BreakoutApp extends StatelessWidget {
  const BreakoutApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Breakout Addiction',
      debugShowCheckedModeBanner: false,
      theme: buildBreakoutTheme(),
      initialRoute: RouteNames.home,
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}
EOD

cat > lib/app/app_router.dart <<'EOD'
import 'package:flutter/material.dart';

import '../core/constants/route_names.dart';
import '../features/home/presentation/home_screen.dart';
import '../features/insights/presentation/insights_screen.dart';
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
      case RouteNames.logHub:
        return MaterialPageRoute(
          builder: (_) => _protect(
            scope: LockScope.logs,
            child: const LogHubScreen(),
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
EOD

cat > lib/app/theme/app_colors.dart <<'EOD'
import 'package:flutter/material.dart';

class AppColors {
  static const background = Color(0xFF0D1117);
  static const surface = Color(0xFF151B23);
  static const surfaceAlt = Color(0xFF1B2330);
  static const accent = Color(0xFF3DD9C5);
  static const accentSoft = Color(0xFF2A9D8F);
  static const textPrimary = Color(0xFFF5F7FA);
  static const textSecondary = Color(0xFF9AA4B2);
  static const success = Color(0xFF4CAF50);
  static const warning = Color(0xFFFFB74D);
  static const danger = Color(0xFFE57373);
  static const divider = Color(0xFF263041);
}
EOD

cat > lib/app/theme/app_spacing.dart <<'EOD'
class AppSpacing {
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 20.0;
  static const xl = 24.0;
  static const xxl = 32.0;
}
EOD

cat > lib/app/theme/app_typography.dart <<'EOD'
import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppTypography {
  static const title = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static const section = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const body = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    height: 1.4,
  );

  static const muted = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    height: 1.4,
  );
}
EOD

cat > lib/app/theme/app_theme.dart <<'EOD'
import 'package:flutter/material.dart';

import 'app_colors.dart';

ThemeData buildBreakoutTheme() {
  final base = ThemeData.dark(useMaterial3: true);

  return base.copyWith(
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: base.colorScheme.copyWith(
      surface: AppColors.surface,
      primary: AppColors.accent,
      secondary: AppColors.accentSoft,
      error: AppColors.danger,
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.divider),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      centerTitle: false,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.accent,
      unselectedItemColor: AppColors.textSecondary,
      type: BottomNavigationBarType.fixed,
      showUnselectedLabels: true,
    ),
  );
}
EOD

cat > lib/core/constants/route_names.dart <<'EOD'
class RouteNames {
  static const home = '/';
  static const rescue = '/rescue';
  static const logHub = '/log';
  static const insights = '/insights';
  static const support = '/support';
}
EOD

cat > lib/core/widgets/info_card.dart <<'EOD'
import 'package:flutter/material.dart';

import '../../app/theme/app_spacing.dart';

class InfoCard extends StatelessWidget {
  final Widget child;

  const InfoCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: child,
      ),
    );
  }
}
EOD

cat > lib/core/widgets/primary_button.dart <<'EOD'
import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final IconData? icon;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon ?? Icons.arrow_forward),
      label: Text(label),
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.black,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
EOD
cat > lib/features/privacy/domain/lock_scope.dart <<'EOD'
enum LockScope {
  app,
  logs,
  cycle,
  support,
  insights,
}
EOD

cat > lib/features/privacy/domain/lock_settings.dart <<'EOD'
import 'lock_scope.dart';

class LockSettings {
  final bool isEnabled;
  final Set<LockScope> enabledScopes;
  final bool allowRescueWithoutUnlock;
  final bool useBiometrics;
  final bool hasPasscode;
  final bool neutralPrivacyMode;

  const LockSettings({
    required this.isEnabled,
    required this.enabledScopes,
    required this.allowRescueWithoutUnlock,
    required this.useBiometrics,
    required this.hasPasscode,
    required this.neutralPrivacyMode,
  });

  factory LockSettings.disabled() {
    return const LockSettings(
      isEnabled: false,
      enabledScopes: <LockScope>{},
      allowRescueWithoutUnlock: true,
      useBiometrics: false,
      hasPasscode: false,
      neutralPrivacyMode: true,
    );
  }

  bool shouldLock(LockScope scope) {
    return isEnabled && enabledScopes.contains(scope);
  }
}
EOD

cat > lib/features/privacy/presentation/lock_gate_screen.dart <<'EOD'
import 'package:flutter/material.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/widgets/info_card.dart';
import '../../../core/widgets/primary_button.dart';

class LockGateScreen extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onUnlockSuccess;

  const LockGateScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.onUnlockSuccess,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Protected')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: InfoCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.title),
                  const SizedBox(height: AppSpacing.sm),
                  Text(subtitle, style: AppTypography.muted),
                  const SizedBox(height: AppSpacing.lg),
                  const TextField(
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Passcode',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  PrimaryButton(
                    label: 'Unlock',
                    icon: Icons.lock_open,
                    onPressed: onUnlockSuccess,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
EOD

cat > lib/features/home/presentation/home_screen.dart <<'EOD'
import 'package:flutter/material.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/constants/route_names.dart';
import '../../../core/widgets/info_card.dart';
import '../../../core/widgets/primary_button.dart';
import 'widgets/daily_quote_card.dart';
import 'widgets/quick_actions_row.dart';
import 'widgets/risk_status_card.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Breakout Addiction'),
        actions: [
          IconButton(
            onPressed: () => Navigator.pushNamed(context, RouteNames.support),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text('Break the cycle earlier.', style: AppTypography.title),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              'Catch the urge before it becomes behavior.',
              style: AppTypography.muted,
            ),
            const SizedBox(height: AppSpacing.lg),
            const DailyQuoteCard(),
            const SizedBox(height: AppSpacing.md),
            const RiskStatusCard(),
            const SizedBox(height: AppSpacing.md),
            const QuickActionsRow(),
            const SizedBox(height: AppSpacing.md),
            InfoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Recovery Cycle Wheel', style: AppTypography.section),
                  const SizedBox(height: AppSpacing.sm),
                  const Text(
                    'Triggers → High Risk → Warning Signs → Fantasies → '
                    'Actions / Behaviors → Short-Lived Pleasure → '
                    'Short-Lived Guilt & Fear → Justifying / Making It Okay',
                    style: AppTypography.muted,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  PrimaryButton(
                    label: 'Open Rescue Now',
                    icon: Icons.health_and_safety_outlined,
                    onPressed: () => Navigator.pushNamed(context, RouteNames.rescue),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            InfoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Progress Snapshot', style: AppTypography.section),
                  SizedBox(height: AppSpacing.sm),
                  Text('Current streak: 0 days', style: AppTypography.body),
                  SizedBox(height: 6),
                  Text('Urges this week: 0', style: AppTypography.body),
                  SizedBox(height: 6),
                  Text('Rescues completed: 0', style: AppTypography.body),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (index) {
          switch (index) {
            case 0:
              break;
            case 1:
              Navigator.pushReplacementNamed(context, RouteNames.rescue);
              break;
            case 2:
              Navigator.pushReplacementNamed(context, RouteNames.logHub);
              break;
            case 3:
              Navigator.pushReplacementNamed(context, RouteNames.insights);
              break;
            case 4:
              Navigator.pushReplacementNamed(context, RouteNames.support);
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.flash_on_outlined), label: 'Rescue'),
          BottomNavigationBarItem(icon: Icon(Icons.edit_note_outlined), label: 'Log'),
          BottomNavigationBarItem(icon: Icon(Icons.insights_outlined), label: 'Insights'),
          BottomNavigationBarItem(icon: Icon(Icons.support_agent_outlined), label: 'Support'),
        ],
      ),
    );
  }
}
EOD

cat > lib/features/home/presentation/widgets/daily_quote_card.dart <<'EOD'
import 'package:flutter/material.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/info_card.dart';

class DailyQuoteCard extends StatelessWidget {
  const DailyQuoteCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Daily Focus', style: AppTypography.section),
          SizedBox(height: AppSpacing.sm),
          Text(
            'You are not your last decision.',
            style: AppTypography.body,
          ),
          SizedBox(height: 6),
          Text(
            'Catch the cycle earlier today.',
            style: AppTypography.muted,
          ),
        ],
      ),
    );
  }
}
EOD

cat > lib/features/home/presentation/widgets/quick_actions_row.dart <<'EOD'
import 'package:flutter/material.dart';

import '../../../../core/constants/route_names.dart';
import '../../../../core/widgets/info_card.dart';

class QuickActionsRow extends StatelessWidget {
  const QuickActionsRow({super.key});

  @override
  Widget build(BuildContext context) {
    return InfoCard(
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          FilledButton.icon(
            onPressed: () => Navigator.pushNamed(context, RouteNames.rescue),
            icon: const Icon(Icons.health_and_safety_outlined),
            label: const Text('I feel an urge'),
          ),
          OutlinedButton.icon(
            onPressed: () => Navigator.pushNamed(context, RouteNames.logHub),
            icon: const Icon(Icons.mood_outlined),
            label: const Text('Log mood'),
          ),
          OutlinedButton.icon(
            onPressed: () => Navigator.pushNamed(context, RouteNames.support),
            icon: const Icon(Icons.call_outlined),
            label: const Text('Call support'),
          ),
        ],
      ),
    );
  }
}
EOD

cat > lib/features/home/presentation/widgets/risk_status_card.dart <<'EOD'
import 'package:flutter/material.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/info_card.dart';

class RiskStatusCard extends StatelessWidget {
  const RiskStatusCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Current Risk Status', style: AppTypography.section),
          SizedBox(height: AppSpacing.sm),
          Chip(label: Text('Guarded')),
          SizedBox(height: 8),
          Text(
            'This is where high-risk time windows, mood patterns, and '
            'recent urges will surface later.',
            style: AppTypography.muted,
          ),
        ],
      ),
    );
  }
}
EOD

cat > lib/features/rescue/presentation/rescue_screen.dart <<'EOD'
import 'package:flutter/material.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/constants/route_names.dart';
import '../../../core/widgets/info_card.dart';
import '../../../core/widgets/primary_button.dart';

class RescueScreen extends StatelessWidget {
  const RescueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Rescue')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text('Pause. You still have a choice.', style: AppTypography.title),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'Interrupt the cycle before it gains momentum.',
              style: AppTypography.muted,
            ),
            const SizedBox(height: AppSpacing.lg),
            const InfoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Urge Intensity', style: AppTypography.section),
                  SizedBox(height: AppSpacing.sm),
                  Slider(value: 4, min: 0, max: 10, onChanged: null),
                  Text('A live slider will be wired in next.', style: AppTypography.muted),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            InfoCard(
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  OutlinedButton(onPressed: () {}, child: const Text('Delay 3 min')),
                  OutlinedButton(onPressed: () {}, child: const Text('Delay 10 min')),
                  OutlinedButton(onPressed: () {}, child: const Text('Delay 15 min')),
                  OutlinedButton(onPressed: () {}, child: const Text('Breathe with me')),
                  OutlinedButton(onPressed: () {}, child: const Text('Leave this room')),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const InfoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Reasons to Stop', style: AppTypography.section),
                  SizedBox(height: AppSpacing.sm),
                  Text('Self-respect • mental clarity • relationships • peace', style: AppTypography.body),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            InfoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Support Actions', style: AppTypography.section),
                  const SizedBox(height: AppSpacing.sm),
                  PrimaryButton(
                    label: 'Open Support',
                    icon: Icons.support_agent_outlined,
                    onPressed: () => Navigator.pushNamed(context, RouteNames.support),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, RouteNames.home);
              break;
            case 1:
              break;
            case 2:
              Navigator.pushReplacementNamed(context, RouteNames.logHub);
              break;
            case 3:
              Navigator.pushReplacementNamed(context, RouteNames.insights);
              break;
            case 4:
              Navigator.pushReplacementNamed(context, RouteNames.support);
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.flash_on_outlined), label: 'Rescue'),
          BottomNavigationBarItem(icon: Icon(Icons.edit_note_outlined), label: 'Log'),
          BottomNavigationBarItem(icon: Icon(Icons.insights_outlined), label: 'Insights'),
          BottomNavigationBarItem(icon: Icon(Icons.support_agent_outlined), label: 'Support'),
        ],
      ),
    );
  }
}
EOD

cat > lib/features/log/presentation/log_hub_screen.dart <<'EOD'
import 'package:flutter/material.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/constants/route_names.dart';
import '../../../core/widgets/info_card.dart';

class LogHubScreen extends StatelessWidget {
  const LogHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Log')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: const [
          InfoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Private Logs', style: AppTypography.section),
                SizedBox(height: AppSpacing.sm),
                Text('Mood log, urge log, relapse log, and victory log land here next.', style: AppTypography.muted),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, RouteNames.home);
              break;
            case 1:
              Navigator.pushReplacementNamed(context, RouteNames.rescue);
              break;
            case 2:
              break;
            case 3:
              Navigator.pushReplacementNamed(context, RouteNames.insights);
              break;
            case 4:
              Navigator.pushReplacementNamed(context, RouteNames.support);
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.flash_on_outlined), label: 'Rescue'),
          BottomNavigationBarItem(icon: Icon(Icons.edit_note_outlined), label: 'Log'),
          BottomNavigationBarItem(icon: Icon(Icons.insights_outlined), label: 'Insights'),
          BottomNavigationBarItem(icon: Icon(Icons.support_agent_outlined), label: 'Support'),
        ],
      ),
    );
  }
}
EOD

cat > lib/features/insights/presentation/insights_screen.dart <<'EOD'
import 'package:flutter/material.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/constants/route_names.dart';
import '../../../core/widgets/info_card.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Insights')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: const [
          InfoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Insights Overview', style: AppTypography.section),
                SizedBox(height: AppSpacing.sm),
                Text('Trend cards, trigger breakdowns, and risk-time patterns will live here.', style: AppTypography.muted),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 3,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, RouteNames.home);
              break;
            case 1:
              Navigator.pushReplacementNamed(context, RouteNames.rescue);
              break;
            case 2:
              Navigator.pushReplacementNamed(context, RouteNames.logHub);
              break;
            case 3:
              break;
            case 4:
              Navigator.pushReplacementNamed(context, RouteNames.support);
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.flash_on_outlined), label: 'Rescue'),
          BottomNavigationBarItem(icon: Icon(Icons.edit_note_outlined), label: 'Log'),
          BottomNavigationBarItem(icon: Icon(Icons.insights_outlined), label: 'Insights'),
          BottomNavigationBarItem(icon: Icon(Icons.support_agent_outlined), label: 'Support'),
        ],
      ),
    );
  }
}
EOD

cat > lib/features/support/presentation/support_screen.dart <<'EOD'
import 'package:flutter/material.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/constants/route_names.dart';
import '../../../core/widgets/info_card.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Support')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: const [
          InfoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Emergency Help', style: AppTypography.section),
                SizedBox(height: AppSpacing.sm),
                Text('988, trusted contacts, and recovery plan shortcuts will live here.', style: AppTypography.muted),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 4,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushReplacementNamed(context, RouteNames.home);
              break;
            case 1:
              Navigator.pushReplacementNamed(context, RouteNames.rescue);
              break;
            case 2:
              Navigator.pushReplacementNamed(context, RouteNames.logHub);
              break;
            case 3:
              Navigator.pushReplacementNamed(context, RouteNames.insights);
              break;
            case 4:
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.flash_on_outlined), label: 'Rescue'),
          BottomNavigationBarItem(icon: Icon(Icons.edit_note_outlined), label: 'Log'),
          BottomNavigationBarItem(icon: Icon(Icons.insights_outlined), label: 'Insights'),
          BottomNavigationBarItem(icon: Icon(Icons.support_agent_outlined), label: 'Support'),
        ],
      ),
    );
  }
}
EOD

cat > tools/verify_scaffold.py <<'EOD'
from pathlib import Path
import sys

REQUIRED = [
    'pubspec.yaml',
    'analysis_options.yaml',
    'lib/main.dart',
    'lib/app/breakout_app.dart',
    'lib/app/app_router.dart',
    'lib/app/theme/app_colors.dart',
    'lib/app/theme/app_theme.dart',
    'lib/core/constants/route_names.dart',
    'lib/core/widgets/info_card.dart',
    'lib/core/widgets/primary_button.dart',
    'lib/features/home/presentation/home_screen.dart',
    'lib/features/rescue/presentation/rescue_screen.dart',
    'lib/features/log/presentation/log_hub_screen.dart',
    'lib/features/insights/presentation/insights_screen.dart',
    'lib/features/support/presentation/support_screen.dart',
    'lib/features/privacy/domain/lock_scope.dart',
    'lib/features/privacy/domain/lock_settings.dart',
    'lib/features/privacy/presentation/lock_gate_screen.dart',
]

def main() -> int:
    root = Path.cwd()
    missing = [path for path in REQUIRED if not (root / path).exists()]
    if missing:
        print('Missing files:')
        for item in missing:
            print(f' - {item}')
        return 1

    print('Breakout Addiction BA-01 scaffold verification passed.')
    print(f'Checked {len(REQUIRED)} required files.')
    return 0

if __name__ == '__main__':
    sys.exit(main())
EOD

echo "==> Scaffold written."
echo "==> Running Python verification..."
python3 tools/verify_scaffold.py
