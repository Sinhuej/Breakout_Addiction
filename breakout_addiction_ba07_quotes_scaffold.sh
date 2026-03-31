#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(pwd)"

echo "==> Applying Breakout Addiction BA-07 quotes scaffold in: $ROOT_DIR"

mkdir -p \
  lib/features/quotes/domain \
  lib/features/quotes/data \
  tools

cat > lib/features/quotes/domain/daily_quote.dart <<'EOD'
enum QuoteMode {
  motivational,
  recovery,
  faith,
}

class DailyQuote {
  final String text;
  final String focusLine;
  final QuoteMode mode;
  final String? religionTag;

  const DailyQuote({
    required this.text,
    required this.focusLine,
    required this.mode,
    this.religionTag,
  });
}
EOD

cat > lib/features/quotes/data/quote_preferences_repository.dart <<'EOD'
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/daily_quote.dart';

class QuotePreferencesRepository {
  static const String _modeKey = 'quote_mode';
  static const String _religionKey = 'quote_religion';

  Future<QuoteMode> getMode() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_modeKey);
    if (raw == null || raw.isEmpty) {
      return QuoteMode.recovery;
    }
    return QuoteMode.values.byName(raw);
  }

  Future<void> saveMode(QuoteMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_modeKey, mode.name);
  }

  Future<String> getReligionTag() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_religionKey) ?? 'Christian';
  }

  Future<void> saveReligionTag(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_religionKey, value);
  }
}
EOD

cat > lib/features/quotes/data/daily_quote_repository.dart <<'EOD'
import '../domain/daily_quote.dart';
import 'quote_preferences_repository.dart';

class DailyQuoteRepository {
  final QuotePreferencesRepository _preferences = QuotePreferencesRepository();

  static const List<DailyQuote> _motivationalQuotes = <DailyQuote>[
    DailyQuote(
      text: 'You are not your last decision.',
      focusLine: 'Build momentum with one strong choice.',
      mode: QuoteMode.motivational,
    ),
    DailyQuote(
      text: 'Small wins count more than perfect intentions.',
      focusLine: 'Keep going, even if the day feels messy.',
      mode: QuoteMode.motivational,
    ),
    DailyQuote(
      text: 'Discipline gets easier when the next step is clear.',
      focusLine: 'Choose clarity over impulse.',
      mode: QuoteMode.motivational,
    ),
  ];

  static const List<DailyQuote> _recoveryQuotes = <DailyQuote>[
    DailyQuote(
      text: 'A craving is a wave, not a command.',
      focusLine: 'Catch the cycle before it speeds up.',
      mode: QuoteMode.recovery,
    ),
    DailyQuote(
      text: 'The earlier you name the pattern, the easier it is to interrupt.',
      focusLine: 'Notice what is building before it peaks.',
      mode: QuoteMode.recovery,
    ),
    DailyQuote(
      text: 'Progress is not erased by a hard moment.',
      focusLine: 'Reset quickly and stay honest.',
      mode: QuoteMode.recovery,
    ),
  ];

  static const List<DailyQuote> _faithQuotes = <DailyQuote>[
    DailyQuote(
      text: 'Grace is stronger than shame.',
      focusLine: 'Take the next faithful step.',
      mode: QuoteMode.faith,
      religionTag: 'Christian',
    ),
    DailyQuote(
      text: 'You do not fight alone today.',
      focusLine: 'Steady your mind and choose what is good.',
      mode: QuoteMode.faith,
      religionTag: 'Christian',
    ),
    DailyQuote(
      text: 'Peace grows where intention is practiced.',
      focusLine: 'Return to your values in this moment.',
      mode: QuoteMode.faith,
      religionTag: 'General Faith',
    ),
  ];

  Future<DailyQuote> getTodayQuote() async {
    final mode = await _preferences.getMode();
    final religion = await _preferences.getReligionTag();

    final DateTime now = DateTime.now();
    final int dayIndex = DateTime(now.year, now.month, now.day)
            .difference(DateTime(2026, 1, 1))
            .inDays
            .abs();

    switch (mode) {
      case QuoteMode.motivational:
        return _motivationalQuotes[dayIndex % _motivationalQuotes.length];
      case QuoteMode.recovery:
        return _recoveryQuotes[dayIndex % _recoveryQuotes.length];
      case QuoteMode.faith:
        final matching = _faithQuotes
            .where((quote) =>
                quote.religionTag == null ||
                quote.religionTag == religion ||
                quote.religionTag == 'General Faith')
            .toList();
        return matching[dayIndex % matching.length];
    }
  }
}
EOD
cat > lib/features/home/presentation/widgets/daily_quote_card.dart <<'EOD'
import 'package:flutter/material.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/info_card.dart';
import '../../../quotes/data/daily_quote_repository.dart';
import '../../../quotes/data/quote_preferences_repository.dart';
import '../../../quotes/domain/daily_quote.dart';

class DailyQuoteCard extends StatelessWidget {
  const DailyQuoteCard({super.key});

  String _modeLabel(QuoteMode mode) {
    switch (mode) {
      case QuoteMode.motivational:
        return 'Motivational';
      case QuoteMode.recovery:
        return 'Recovery';
      case QuoteMode.faith:
        return 'Faith';
    }
  }

  @override
  Widget build(BuildContext context) {
    final repository = DailyQuoteRepository();
    final preferences = QuotePreferencesRepository();

    return FutureBuilder<List<dynamic>>(
      future: Future.wait<dynamic>([
        repository.getTodayQuote(),
        preferences.getMode(),
        preferences.getReligionTag(),
      ]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const InfoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Daily Focus', style: AppTypography.section),
                SizedBox(height: AppSpacing.sm),
                Text('Loading encouragement...', style: AppTypography.muted),
              ],
            ),
          );
        }

        final results = snapshot.data;
        if (results == null || results.length < 3) {
          return const InfoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Daily Focus', style: AppTypography.section),
                SizedBox(height: AppSpacing.sm),
                Text('Unable to load quote right now.', style: AppTypography.muted),
              ],
            ),
          );
        }

        final quote = results[0] as DailyQuote;
        final mode = results[1] as QuoteMode;
        final religion = results[2] as String;

        return InfoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Daily Focus', style: AppTypography.section),
              const SizedBox(height: AppSpacing.sm),
              Text(
                quote.text,
                style: AppTypography.body,
              ),
              const SizedBox(height: 6),
              Text(
                quote.focusLine,
                style: AppTypography.muted,
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(label: Text(_modeLabel(mode))),
                  if (mode == QuoteMode.faith) Chip(label: Text(religion)),
                ],
              ),
            ],
          ),
        );
      },
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
import '../../../core/widgets/primary_button.dart';
import '../../quotes/data/quote_preferences_repository.dart';
import '../../quotes/domain/daily_quote.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final QuotePreferencesRepository _quotePreferences = QuotePreferencesRepository();

  QuoteMode _mode = QuoteMode.recovery;
  String _religion = 'Christian';
  bool _loading = true;

  static const List<String> _religions = <String>[
    'Christian',
    'General Faith',
    'Secular',
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final mode = await _quotePreferences.getMode();
    final religion = await _quotePreferences.getReligionTag();

    if (!mounted) {
      return;
    }

    setState(() {
      _mode = mode;
      _religion = religion;
      _loading = false;
    });
  }

  Future<void> _saveMode(QuoteMode mode) async {
    await _quotePreferences.saveMode(mode);
    if (!mounted) {
      return;
    }
    setState(() => _mode = mode);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Saved ${mode.name} quote mode.')),
    );
  }

  Future<void> _saveReligion(String value) async {
    await _quotePreferences.saveReligionTag(value);
    if (!mounted) {
      return;
    }
    setState(() => _religion = value);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Saved faith preference: $value.')),
    );
  }

  Widget _modeButton({
    required String label,
    required QuoteMode mode,
  }) {
    final selected = _mode == mode;
    return Expanded(
      child: OutlinedButton(
        onPressed: () => _saveMode(mode),
        child: Text(selected ? '$label ✓' : label),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        appBar: AppBar(title: Text('Support')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Support')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          const InfoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Emergency Help', style: AppTypography.section),
                SizedBox(height: AppSpacing.sm),
                Text(
                  '988, trusted contacts, and recovery plan shortcuts will live here.',
                  style: AppTypography.muted,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          InfoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Daily Encouragement', style: AppTypography.section),
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  'Choose the tone you want on the Home screen.',
                  style: AppTypography.muted,
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    _modeButton(label: 'Motivational', mode: QuoteMode.motivational),
                    const SizedBox(width: 8),
                    _modeButton(label: 'Recovery', mode: QuoteMode.recovery),
                    const SizedBox(width: 8),
                    _modeButton(label: 'Faith', mode: QuoteMode.faith),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                DropdownButtonFormField<String>(
                  value: _religion,
                  decoration: const InputDecoration(
                    labelText: 'Faith / Religion Preference',
                    border: OutlineInputBorder(),
                  ),
                  items: _religions
                      .map(
                        (item) => DropdownMenuItem<String>(
                          value: item,
                          child: Text(item),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    _saveReligion(value);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          InfoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Privacy & Lock Mode', style: AppTypography.section),
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  'Control who can open the app or view private areas like logs and cycle history.',
                  style: AppTypography.muted,
                ),
                const SizedBox(height: AppSpacing.md),
                PrimaryButton(
                  label: 'Open Privacy Settings',
                  icon: Icons.lock_outline,
                  onPressed: () => Navigator.pushNamed(
                    context,
                    RouteNames.privacySettings,
                  ),
                ),
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
cat > tools/verify_ba07.py <<'EOD'
from pathlib import Path
import sys

REQUIRED = [
    'lib/features/quotes/domain/daily_quote.dart',
    'lib/features/quotes/data/quote_preferences_repository.dart',
    'lib/features/quotes/data/daily_quote_repository.dart',
    'lib/features/home/presentation/widgets/daily_quote_card.dart',
    'lib/features/support/presentation/support_screen.dart',
]

REQUIRED_TEXT = {
    'lib/features/quotes/domain/daily_quote.dart': 'enum QuoteMode',
    'lib/features/quotes/data/quote_preferences_repository.dart': 'class QuotePreferencesRepository',
    'lib/features/quotes/data/daily_quote_repository.dart': 'class DailyQuoteRepository',
    'lib/features/home/presentation/widgets/daily_quote_card.dart': 'DailyQuoteRepository',
    'lib/features/support/presentation/support_screen.dart': 'Daily Encouragement',
}

def main() -> int:
    root = Path.cwd()

    missing = [path for path in REQUIRED if not (root / path).exists()]
    if missing:
        print('Missing files:')
        for item in missing:
            print(f' - {item}')
        return 1

    bad = []
    for path, needle in REQUIRED_TEXT.items():
        text = (root / path).read_text(encoding='utf-8')
        if needle not in text:
            bad.append((path, needle))

    if bad:
        print('Content checks failed:')
        for path, needle in bad:
            print(f' - {path} missing: {needle}')
        return 1

    print('Breakout Addiction BA-07 quotes scaffold verification passed.')
    print(f'Checked {len(REQUIRED)} files and {len(REQUIRED_TEXT)} content rules.')
    return 0

if __name__ == '__main__':
    sys.exit(main())
EOD

echo "==> BA-07 quotes scaffold written."
echo "==> Running Python verification..."
python3 tools/verify_ba07.py
