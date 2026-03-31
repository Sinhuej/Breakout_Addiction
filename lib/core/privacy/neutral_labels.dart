class NeutralLabels {
  static String rescuePrimary(bool neutralMode) {
    return neutralMode ? 'Daily Reset' : 'I feel an urge';
  }

  static String moodLog(bool neutralMode) {
    return neutralMode ? 'Log Check-In' : 'Log mood';
  }

  static String supportAction(bool neutralMode) {
    return neutralMode ? 'Contact Support' : 'Call support';
  }

  static String riskCardAction(bool neutralMode) {
    return neutralMode ? 'Log Check-In Now' : 'Log Mood Now';
  }

  static String widgetHome(bool neutralMode) {
    return neutralMode ? 'Open Breakout' : 'Open Breakout';
  }

  static String widgetRescue(bool neutralMode) {
    return neutralMode ? 'Daily Reset' : 'Open Rescue';
  }

  static String widgetMood(bool neutralMode) {
    return neutralMode ? 'Log Check-In' : 'Log Mood';
  }

  static String cycleWheelTitle(bool neutralMode) {
    return neutralMode ? 'Pattern Wheel' : 'Recovery Cycle Wheel';
  }

  static String logHubTitle(bool neutralMode) {
    return neutralMode ? 'Private Check-Ins' : 'Private Logs';
  }
}
