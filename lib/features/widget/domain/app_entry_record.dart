class AppEntryRecord {
  final String sourceKey;
  final String routeName;
  final String title;
  final String subtitle;
  final DateTime timestamp;

  const AppEntryRecord({
    required this.sourceKey,
    required this.routeName,
    required this.title,
    required this.subtitle,
    required this.timestamp,
  });

  factory AppEntryRecord.normal() {
    return AppEntryRecord(
      sourceKey: 'normal_open',
      routeName: '/',
      title: 'Normal App Open',
      subtitle: 'The app was opened normally.',
      timestamp: DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'sourceKey': sourceKey,
      'routeName': routeName,
      'title': title,
      'subtitle': subtitle,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory AppEntryRecord.fromMap(Map<String, dynamic> map) {
    return AppEntryRecord(
      sourceKey: (map['sourceKey'] as String?) ?? 'normal_open',
      routeName: (map['routeName'] as String?) ?? '/',
      title: (map['title'] as String?) ?? 'Normal App Open',
      subtitle: (map['subtitle'] as String?) ?? 'The app was opened normally.',
      timestamp: DateTime.tryParse((map['timestamp'] as String?) ?? '') ??
          DateTime.now(),
    );
  }

  bool get isWidgetEntry => sourceKey.startsWith('widget_');
}
