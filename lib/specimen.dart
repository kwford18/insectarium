class LifeStageDefinition {
  const LifeStageDefinition(this.label, {this.nextStages = const {}});

  final String label;
  final Set<String> nextStages;
}

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
  final String initialStageId;
  final Map<String, LifeStageDefinition> stages;
  final Map<String, String> behaviors;
}

class Specimen {
  const Specimen({required this.id, required this.species});

  final String id;
  final SpeciesDefinition species;
}

const woodlandStickInsect = Specimen(
  id: 'woodland-stick-insect',
  species: SpeciesDefinition(
    id: 'woodland-phasmid',
    name: 'Stick insect',
    initialStageId: 'adult',
    stages: {'adult': LifeStageDefinition('Adult')},
    behaviors: {
      'resting': 'Resting',
      'climbing': 'Climbing',
      'walking': 'Walking',
    },
  ),
);
