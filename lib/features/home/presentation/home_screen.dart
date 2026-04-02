import 'package:flutter/material.dart';

import '../../../app/theme/app_spacing.dart';
import '../../../core/constants/route_names.dart';
import '../../../core/widgets/info_card.dart';
import '../../../core/widgets/primary_button.dart';
import '../../settings/data/feature_control_settings_repository.dart';
import '../../settings/domain/feature_control_settings.dart';
import 'widgets/daily_quote_card.dart';
import 'widgets/home_hero_card.dart';
import 'widgets/progress_snapshot_card.dart';
import 'widgets/quick_actions_row.dart';
import 'widgets/risk_status_card.dart';
import 'widgets/startup_notice_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static bool _startupNoticeHandledThisSession = false;
  final FeatureControlSettingsRepository _settingsRepository =
      FeatureControlSettingsRepository();

  @override
  void initState() {
    super.initState();
    _maybeShowStartupNotice();
  }

  Future<void> _maybeShowStartupNotice() async {
    final settings = await _settingsRepository.getSettings();
    if (!mounted) {
      return;
    }

    if (!settings.showStartupNotice || _startupNoticeHandledThisSession) {
      return;
    }

    _startupNoticeHandledThisSession = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      var currentSettings = settings;

      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (sheetContext) {
          return StatefulBuilder(
            builder: (context, setSheetState) {
              return StartupNoticeSheet(
                showOnStartup: currentSettings.showStartupNotice,
                onShowOnStartupChanged: (value) async {
                  currentSettings =
                      currentSettings.copyWith(showStartupNotice: value);
                  await _settingsRepository.saveSettings(currentSettings);
                  setSheetState(() {});
                },
                onContinue: () {
                  Navigator.pop(sheetContext);
                },
                onOpenFeatureChoices: () {
                  Navigator.pop(sheetContext);
                  Navigator.pushNamed(context, RouteNames.featureControls);
                },
                onOpenSupport: () {
                  Navigator.pop(sheetContext);
                  Navigator.pushNamed(context, RouteNames.support);
                },
              );
            },
          );
        },
      );
    });
  }

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
            const HomeHeroCard(),
            const SizedBox(height: AppSpacing.md),
            const DailyQuoteCard(),
            const SizedBox(height: AppSpacing.md),
            const RiskStatusCard(),
            const SizedBox(height: AppSpacing.md),
            const QuickActionsRow(),
            const SizedBox(height: AppSpacing.md),
            const ProgressSnapshotCard(),
            const SizedBox(height: AppSpacing.md),
            InfoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Keep Building'),
                  const SizedBox(height: AppSpacing.sm),
                  const Text(
                    'Use Learn for deeper understanding and Support for your personal plan, privacy settings, premium choices, and feature controls.',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  PrimaryButton(
                    label: 'Open Learn',
                    icon: Icons.menu_book_outlined,
                    onPressed: () => Navigator.pushNamed(
                      context,
                      RouteNames.educate,
                    ),
                  ),
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
