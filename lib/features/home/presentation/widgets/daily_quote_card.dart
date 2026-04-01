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
