/// An event reported by the simulation for a single specimen
///
/// The stage identifies when the event happened, so the journal can reject
/// events from an earlier stage and keep feeding records tied to the right one
sealed class SpecimenObservation {
  const SpecimenObservation({
    required this.specimenId,
    required this.stageId,
    required this.recordedAt,
  });

  final String specimenId;

  /// Stage at the time of the event, including the source of a transition
  final String stageId;

  /// Clock time used for recent activity when the event is logged
  final DateTime recordedAt;
}

/// Updates the live behavior shown in the journal without adding history
///
/// The producer reports transitions using IDs from the species definition
class BehaviorChanged extends SpecimenObservation {
  const BehaviorChanged({
    required super.specimenId,
    required super.stageId,
    required super.recordedAt,
    required this.behaviorId,
  });

  final String behaviorId;
}

/// Updates a known fact by ID, with an optional entry for recent activity
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

  /// Supply a message for milestones that belong in the recent activity list
  final String? activityMessage;
}

/// Reports a completed feeding so the journal can count it for this stage
///
/// A food ID joins repeated feedings into one record within the stage.
/// The count records what was eaten and can provide evidence for later mechanics
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

/// Reports a transition from [SpecimenObservation.stageId] to [nextStageId]
class LifeStageChanged extends SpecimenObservation {
  const LifeStageChanged({
    required super.specimenId,
    required super.stageId,
    required super.recordedAt,
    required this.nextStageId,
  });

  final String nextStageId;
}

/// Records a newly recognized form of the same specimen
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
