import 'package:flutter/material.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/info_card.dart';
import '../../../widget/data/app_entry_repository.dart';
import '../../../widget/domain/app_entry_record.dart';

class EntryStatusCard extends StatefulWidget {
  const EntryStatusCard({super.key});

  @override
  State<EntryStatusCard> createState() => _EntryStatusCardState();
}

class _EntryStatusCardState extends State<EntryStatusCard> {
  final AppEntryRepository _repository = AppEntryRepository();
  AppEntryRecord? _entry;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final entry = await _repository.getLastEntry();
    if (!mounted) {
      return;
    }
    setState(() {
      _entry = entry;
      _loading = false;
    });
  }

  Future<void> _dismiss() async {
    await _repository.clearLastEntry();
    if (!mounted) {
      return;
    }
    setState(() => _entry = null);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _entry == null || !_entry!.isWidgetEntry) {
      return const SizedBox.shrink();
    }

    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Recent App Entry', style: AppTypography.section),
          const SizedBox(height: AppSpacing.sm),
          Text(_entry!.title, style: AppTypography.body),
          const SizedBox(height: 6),
          Text(_entry!.subtitle, style: AppTypography.muted),
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _dismiss,
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Dismiss Entry Status'),
            ),
          ),
        ],
      ),
    );
  }
}
