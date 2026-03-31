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
