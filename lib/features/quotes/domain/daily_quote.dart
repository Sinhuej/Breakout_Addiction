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
