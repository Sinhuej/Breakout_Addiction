enum CycleStage {
  triggers,
  highRisk,
  warningSigns,
  fantasies,
  actionsBehaviors,
  shortLivedPleasure,
  shortLivedGuiltFear,
  justifyingMakingItOkay,
}

extension CycleStageX on CycleStage {
  String get shortLabel {
    switch (this) {
      case CycleStage.triggers:
        return 'Triggers';
      case CycleStage.highRisk:
        return 'High Risk';
      case CycleStage.warningSigns:
        return 'Warning Signs';
      case CycleStage.fantasies:
        return 'Fantasies';
      case CycleStage.actionsBehaviors:
        return 'Actions';
      case CycleStage.shortLivedPleasure:
        return 'Pleasure';
      case CycleStage.shortLivedGuiltFear:
        return 'Guilt & Fear';
      case CycleStage.justifyingMakingItOkay:
        return 'Justifying';
    }
  }

  String get title {
    switch (this) {
      case CycleStage.triggers:
        return 'Triggers';
      case CycleStage.highRisk:
        return 'High Risk';
      case CycleStage.warningSigns:
        return 'Warning Signs';
      case CycleStage.fantasies:
        return 'Fantasies';
      case CycleStage.actionsBehaviors:
        return 'Actions / Behaviors';
      case CycleStage.shortLivedPleasure:
        return 'Short-Lived Pleasure';
      case CycleStage.shortLivedGuiltFear:
        return 'Short-Lived Guilt & Fear';
      case CycleStage.justifyingMakingItOkay:
        return 'Justifying / Making It Okay';
    }
  }

  String get description {
    switch (this) {
      case CycleStage.triggers:
        return 'The moments, emotions, places, or situations that start the cycle.';
      case CycleStage.highRisk:
        return 'Settings or times when acting out becomes more likely unless interrupted early.';
      case CycleStage.warningSigns:
        return 'The subtle signals that tell you the cycle is gaining momentum.';
      case CycleStage.fantasies:
        return 'Mental drift, urge replay, and imagination patterns that pull attention deeper.';
      case CycleStage.actionsBehaviors:
        return 'The choices, rituals, and behaviors that move from urge toward acting out.';
      case CycleStage.shortLivedPleasure:
        return 'A temporary reward or relief that fades quickly.';
      case CycleStage.shortLivedGuiltFear:
        return 'The emotional crash, shame, fear, or regret that often follows.';
      case CycleStage.justifyingMakingItOkay:
        return 'The internal permission-giving that lowers resistance and restarts the cycle.';
    }
  }

  List<String> get examples {
    switch (this) {
      case CycleStage.triggers:
        return ['Loneliness', 'Stress', 'Boredom', 'Late-night phone use'];
      case CycleStage.highRisk:
        return ['Alone in bed', 'After an argument', 'After alcohol', 'Long scrolling sessions'];
      case CycleStage.warningSigns:
        return ['Restless mood', 'Hiding behavior', 'Rationalizing', '“Just a quick look”'];
      case CycleStage.fantasies:
        return ['Mental replay', 'Escaping into imagination', 'Curiosity building', 'Urge spikes'];
      case CycleStage.actionsBehaviors:
        return ['Searching', 'Scrolling', 'Opening risky apps', 'Extending the ritual'];
      case CycleStage.shortLivedPleasure:
        return ['Relief', 'Escape', 'Numbing out', 'Temporary calm'];
      case CycleStage.shortLivedGuiltFear:
        return ['Shame', 'Regret', 'Fear of being caught', 'Feeling stuck'];
      case CycleStage.justifyingMakingItOkay:
        return ['“I already messed up”', '“One last time”', '“I’ll restart tomorrow”', '“It’s not a big deal”'];
    }
  }
}
