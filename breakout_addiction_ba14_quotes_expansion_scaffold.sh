#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(pwd)"

echo "==> Applying Breakout Addiction BA-14 quotes expansion scaffold in: $ROOT_DIR"

mkdir -p \
  lib/features/quotes/domain \
  lib/features/quotes/data \
  lib/features/home/presentation/widgets \
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
  final String? wisdomLine;

  const DailyQuote({
    required this.text,
    required this.focusLine,
    required this.mode,
    this.religionTag,
    this.wisdomLine,
  });
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
    DailyQuote(
      text: 'The next right move matters more than the last wrong one.',
      focusLine: 'Recover faster than you criticize yourself.',
      mode: QuoteMode.motivational,
    ),
    DailyQuote(
      text: 'Consistency beats intensity when you are changing a pattern.',
      focusLine: 'Win this moment, then the next one.',
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
    DailyQuote(
      text: 'Urges grow in silence and shrink in honest light.',
      focusLine: 'Log it. Name it. Reduce its mystery.',
      mode: QuoteMode.recovery,
    ),
    DailyQuote(
      text: 'Recovery often looks like earlier awareness, not dramatic perfection.',
      focusLine: 'Spot the setup sooner.',
      mode: QuoteMode.recovery,
    ),
  ];

  static const List<DailyQuote> _faithQuotes = <DailyQuote>[
    DailyQuote(
      text: 'Grace is stronger than shame.',
      focusLine: 'Take the next faithful step.',
      mode: QuoteMode.faith,
      religionTag: 'Christian',
      wisdomLine: 'Choose honesty over hiding today.',
    ),
    DailyQuote(
      text: 'You do not fight alone today.',
      focusLine: 'Steady your mind and choose what is good.',
      mode: QuoteMode.faith,
      religionTag: 'Christian',
      wisdomLine: 'Strength grows when you return instead of withdraw.',
    ),
    DailyQuote(
      text: 'Peace grows where intention is practiced.',
      focusLine: 'Return to your values in this moment.',
      mode: QuoteMode.faith,
      religionTag: 'General Faith',
      wisdomLine: 'Your habits follow what you repeatedly honor.',
    ),
    DailyQuote(
      text: 'Mercy is not permission to quit trying.',
      focusLine: 'Stand up again without self-hatred.',
      mode: QuoteMode.faith,
      religionTag: 'Christian',
      wisdomLine: 'Repentance is movement, not performance.',
    ),
    DailyQuote(
      text: 'Inner discipline grows through repeated surrender.',
      focusLine: 'Choose what leads to peace, not secrecy.',
      mode: QuoteMode.faith,
      religionTag: 'General Faith',
      wisdomLine: 'The calmer path is often the stronger one.',
    ),
  ];

  Future<DailyQuote> getTodayQuote() async {
    final mode = await _preferences.getMode();
    final religion = await _preferences.getReligionTag();

    final now = DateTime.now();
    final dayIndex = DateTime(now.year, now.month, now.day)
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
              if (quote.wisdomLine != null && quote.wisdomLine!.trim().isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  quote.wisdomLine!,
                  style: AppTypography.body,
                ),
              ],
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

python3 - <<'EOD'
from pathlib import Path

path = Path('lib/features/support/presentation/support_screen.dart')
text = path.read_text(encoding='utf-8')
old = 'Choose the tone you want on the Home screen.'
new = 'Choose the tone and faith layer you want on the Home screen.'
if old in text:
    text = text.replace(old, new)
path.write_text(text, encoding='utf-8')
print('Patched support_screen.dart')
EOD
cat > tools/verify_ba14.py <<'EOD'
from pathlib import Path
import sys

REQUIRED = [
    'lib/features/quotes/domain/daily_quote.dart',
    'lib/features/quotes/data/daily_quote_repository.dart',
    'lib/features/home/presentation/widgets/daily_quote_card.dart',
    'lib/features/support/presentation/support_screen.dart',
]

REQUIRED_TEXT = {
    'lib/features/quotes/domain/daily_quote.dart': 'final String? wisdomLine;',
    'lib/features/quotes/data/daily_quote_repository.dart': 'Mercy is not permission to quit trying.',
    'lib/features/home/presentation/widgets/daily_quote_card.dart': 'quote.wisdomLine',
    'lib/features/support/presentation/support_screen.dart': 'Choose the tone and faith layer you want on the Home screen.',
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

    print('Breakout Addiction BA-14 quote expansion verification passed.')
    print(f'Checked {len(REQUIRED)} files and {len(REQUIRED_TEXT)} content rules.')
    return 0

if __name__ == '__main__':
    sys.exit(main())
EOD

echo "==> BA-14 quotes expansion scaffold written."
echo "==> Running Python verification..."
python3 tools/verify_ba14.py
