import '../../../core/constants/route_names.dart';

enum WidgetEntryAction {
  openHome,
  openRescue,
  openMoodLog,
}

extension WidgetEntryActionX on WidgetEntryAction {
  String get routeName {
    switch (this) {
      case WidgetEntryAction.openHome:
        return RouteNames.home;
      case WidgetEntryAction.openRescue:
        return RouteNames.rescue;
      case WidgetEntryAction.openMoodLog:
        return RouteNames.moodLog;
    }
  }

  String get deepLinkKey {
    switch (this) {
      case WidgetEntryAction.openHome:
        return 'home';
      case WidgetEntryAction.openRescue:
        return 'rescue';
      case WidgetEntryAction.openMoodLog:
        return 'mood';
    }
  }
}
