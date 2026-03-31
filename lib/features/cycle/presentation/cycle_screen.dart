import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_spacing.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/constants/route_names.dart';
import '../../../core/widgets/info_card.dart';
import '../../../core/widgets/primary_button.dart';
import '../domain/cycle_stage.dart';

class CycleScreen extends StatelessWidget {
  const CycleScreen({super.key});

  void _showStageSheet(BuildContext context, CycleStage stage) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(stage.title, style: AppTypography.title),
                const SizedBox(height: AppSpacing.sm),
                Text(stage.description, style: AppTypography.muted),
                const SizedBox(height: AppSpacing.lg),
                Text('Examples', style: AppTypography.section),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: stage.examples
                      .map((item) => Chip(label: Text(item)))
                      .toList(),
                ),
                const SizedBox(height: AppSpacing.lg),
                PrimaryButton(
                  label: 'Log This Stage',
                  icon: Icons.add_task_outlined,
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    Navigator.pushNamed(
                      context,
                      RouteNames.cycleStageLog,
                      arguments: stage,
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      Navigator.pushNamed(context, RouteNames.rescue);
                    },
                    icon: const Icon(Icons.health_and_safety_outlined),
                    label: const Text('Open Rescue'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cycle Wheel')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text('Recognize the cycle earlier.', style: AppTypography.title),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              'Tap any stage to explore it, reflect on it, and interrupt it faster.',
              style: AppTypography.muted,
            ),
            const SizedBox(height: AppSpacing.lg),
            Center(
              child: _CycleWheel(
                onStageTap: (stage) => _showStageSheet(context, stage),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            const InfoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('How to use this', style: AppTypography.section),
                  SizedBox(height: AppSpacing.sm),
                  Text(
                    'Use the wheel to name where you are before the cycle speeds up. '
                    'The earlier you spot the pattern, the easier it is to interrupt.',
                    style: AppTypography.muted,
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

class _CycleWheel extends StatelessWidget {
  final ValueChanged<CycleStage> onStageTap;

  const _CycleWheel({
    required this.onStageTap,
  });

  @override
  Widget build(BuildContext context) {
    const double wheelSize = 360;
    const double bubbleSize = 84;
    const double radius = 128;
    const double center = wheelSize / 2;

    return SizedBox(
      width: wheelSize,
      height: wheelSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 170,
            height: 170,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surfaceAlt,
              border: Border.all(color: AppColors.divider),
            ),
            alignment: Alignment.center,
            padding: const EdgeInsets.all(AppSpacing.md),
            child: const Text(
              'Recovery\nCycle',
              textAlign: TextAlign.center,
              style: AppTypography.section,
            ),
          ),
          for (int index = 0; index < CycleStage.values.length; index++)
            _buildStageBubble(
              stage: CycleStage.values[index],
              index: index,
              bubbleSize: bubbleSize,
              center: center,
              radius: radius,
            ),
        ],
      ),
    );
  }

  Widget _buildStageBubble({
    required CycleStage stage,
    required int index,
    required double bubbleSize,
    required double center,
    required double radius,
  }) {
    final angle = (-math.pi / 2) + ((2 * math.pi) / CycleStage.values.length) * index;
    final left = center + radius * math.cos(angle) - (bubbleSize / 2);
    final top = center + radius * math.sin(angle) - (bubbleSize / 2);

    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        onTap: () => onStageTap(stage),
        child: Container(
          width: bubbleSize,
          height: bubbleSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.surface,
            border: Border.all(color: AppColors.accent),
            boxShadow: const [
              BoxShadow(
                blurRadius: 10,
                spreadRadius: 0,
                offset: Offset(0, 4),
                color: Color(0x22000000),
              ),
            ],
          ),
          alignment: Alignment.center,
          padding: const EdgeInsets.all(8),
          child: Text(
            stage.shortLabel,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              height: 1.15,
            ),
          ),
        ),
      ),
    );
  }
}
