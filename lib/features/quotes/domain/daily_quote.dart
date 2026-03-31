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
