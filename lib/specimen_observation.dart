sealed class SpecimenObservation {
  const SpecimenObservation({
    required this.specimenId,
    required this.stageId,
    required this.recordedAt,
  });

  final String specimenId;
  final String stageId;
  final DateTime recordedAt;
}

class BehaviorChanged extends SpecimenObservation {
  const BehaviorChanged({
    required super.specimenId,
    required super.stageId,
    required super.recordedAt,
    required this.behaviorId,
  });

  final String behaviorId;
}

class DiscoveryObserved extends SpecimenObservation {
  const DiscoveryObserved({
    required super.specimenId,
    required super.stageId,
    required super.recordedAt,
    required this.id,
    required this.description,
    this.activityMessage,
  });

  final String id;
  final String description;
  final String? activityMessage;
}

class FoodEaten extends SpecimenObservation {
  const FoodEaten({
    required super.specimenId,
    required super.stageId,
    required super.recordedAt,
    required this.foodId,
    required this.foodName,
  });

  final String foodId;
  final String foodName;
}

class LifeStageChanged extends SpecimenObservation {
  const LifeStageChanged({
    required super.specimenId,
    required super.stageId,
    required super.recordedAt,
    required this.nextStageId,
  });

  final String nextStageId;
}

class MorphIdentified extends SpecimenObservation {
  const MorphIdentified({
    required super.specimenId,
    required super.stageId,
    required super.recordedAt,
    required this.morphId,
    required this.label,
  });

  final String morphId;
  final String label;
}
