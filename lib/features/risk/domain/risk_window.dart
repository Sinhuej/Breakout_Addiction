class RiskWindow {
  final String id;
  final String label;
  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;
  final bool isEnabled;

  const RiskWindow({
    required this.id,
    required this.label,
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
    required this.isEnabled,
  });

  RiskWindow copyWith({
    String? id,
    String? label,
    int? startHour,
    int? startMinute,
    int? endHour,
    int? endMinute,
    bool? isEnabled,
  }) {
    return RiskWindow(
      id: id ?? this.id,
      label: label ?? this.label,
      startHour: startHour ?? this.startHour,
      startMinute: startMinute ?? this.startMinute,
      endHour: endHour ?? this.endHour,
      endMinute: endMinute ?? this.endMinute,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'label': label,
      'startHour': startHour,
      'startMinute': startMinute,
      'endHour': endHour,
      'endMinute': endMinute,
      'isEnabled': isEnabled,
    };
  }

  factory RiskWindow.fromMap(Map<String, dynamic> map) {
    return RiskWindow(
      id: (map['id'] as String?) ?? '',
      label: (map['label'] as String?) ?? 'Risk Window',
      startHour: (map['startHour'] as num?)?.toInt() ?? 22,
      startMinute: (map['startMinute'] as num?)?.toInt() ?? 0,
      endHour: (map['endHour'] as num?)?.toInt() ?? 23,
      endMinute: (map['endMinute'] as num?)?.toInt() ?? 0,
      isEnabled: (map['isEnabled'] as bool?) ?? true,
    );
  }

  String get timeRange {
    return '${_fmt(startHour)}:${_fmt(startMinute)} - ${_fmt(endHour)}:${_fmt(endMinute)}';
  }

  static String _fmt(int value) => value.toString().padLeft(2, '0');
}
