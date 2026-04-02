class RecoveryPlan {
  final List<String> riskyPlaces;
  final String firstAction;
  final String secondAction;
  final String groundingAction;
  final String supportPerson;
  final String fallbackPlan;

  const RecoveryPlan({
    required this.riskyPlaces,
    required this.firstAction,
    required this.secondAction,
    required this.groundingAction,
    required this.supportPerson,
    required this.fallbackPlan,
  });

  factory RecoveryPlan.defaults() {
    return const RecoveryPlan(
      riskyPlaces: <String>[],
      firstAction: '',
      secondAction: '',
      groundingAction: '',
      supportPerson: '',
      fallbackPlan: '',
    );
  }

  RecoveryPlan copyWith({
    List<String>? riskyPlaces,
    String? firstAction,
    String? secondAction,
    String? groundingAction,
    String? supportPerson,
    String? fallbackPlan,
  }) {
    return RecoveryPlan(
      riskyPlaces: riskyPlaces ?? this.riskyPlaces,
      firstAction: firstAction ?? this.firstAction,
      secondAction: secondAction ?? this.secondAction,
      groundingAction: groundingAction ?? this.groundingAction,
      supportPerson: supportPerson ?? this.supportPerson,
      fallbackPlan: fallbackPlan ?? this.fallbackPlan,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'riskyPlaces': riskyPlaces,
      'firstAction': firstAction,
      'secondAction': secondAction,
      'groundingAction': groundingAction,
      'supportPerson': supportPerson,
      'fallbackPlan': fallbackPlan,
    };
  }

  factory RecoveryPlan.fromMap(Map<String, dynamic> map) {
    return RecoveryPlan(
      riskyPlaces: (map['riskyPlaces'] as List<dynamic>? ?? <dynamic>[])
          .map((item) => item.toString())
          .toList(),
      firstAction: (map['firstAction'] as String?) ?? '',
      secondAction: (map['secondAction'] as String?) ?? '',
      groundingAction: (map['groundingAction'] as String?) ?? '',
      supportPerson: (map['supportPerson'] as String?) ?? '',
      fallbackPlan: (map['fallbackPlan'] as String?) ?? '',
    );
  }
}
