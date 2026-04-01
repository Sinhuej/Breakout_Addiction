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
