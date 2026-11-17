/// A lifecycle stage and the stages this species can enter from it
class LifeStageDefinition {
  const LifeStageDefinition(this.label, {this.nextStages = const {}});

  final String label;

  /// Allowed successor IDs. An empty set marks a terminal stage
  final Set<String> nextStages;
}

/// Shared labels and lifecycle rules for all specimens of a species
///
/// Keep species and stage IDs stable across saves so their display labels can
/// change independently. The entry stage and successors refer to [stages]
class SpeciesDefinition {
  const SpeciesDefinition({
    required this.id,
    required this.name,
    required this.initialStageId,
    required this.stages,
    required this.behaviors,
  });

  final String id;
  final String name;

  /// The stage a new journal uses before restoring any saved history
  final String initialStageId;
  final Map<String, LifeStageDefinition> stages;

  /// Supported behavior IDs and the labels shown in the live journal
  final Map<String, String> behaviors;
}

/// An individual whose identity stays the same across life-stage changes
///
/// Its ID identifies the save and the target of observations, so several
/// specimens can share one species definition and keep separate histories
class Specimen {
  const Specimen({required this.id, required this.species});

  final String id;
  final SpeciesDefinition species;
}

/// The individual placed in the current woodland prototype
const woodlandStickInsect = Specimen(
  id: 'woodland-stick-insect',
  species: SpeciesDefinition(
    id: 'woodland-phasmid',
    name: 'Stick insect',
    initialStageId: 'adult',
    stages: {'adult': LifeStageDefinition('Adult')},
    behaviors: {
      'feeding': 'Feeding',
      'resting': 'Resting',
      'climbing': 'Climbing',
      'walking': 'Walking',
    },
  ),
);
