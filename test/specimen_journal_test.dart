import 'dart:ui' show Offset, Size;

import 'package:flutter_test/flutter_test.dart';
import 'package:insect_sanctuary/main.dart';
import 'package:insect_sanctuary/specimen.dart';
import 'package:insect_sanctuary/specimen_journal.dart';
import 'package:insect_sanctuary/specimen_observation.dart';

// A species with multiple stages exercises the same journal through metamorphosis
const _caterpillar = Specimen(
  id: 'caterpillar-1',
  species: SpeciesDefinition(
    id: 'test-butterfly',
    name: 'Test butterfly',
    initialStageId: 'larva',
    stages: {
      'larva': LifeStageDefinition('Larva', nextStages: {'pupa'}),
      'pupa': LifeStageDefinition('Pupa', nextStages: {'adult'}),
      'adult': LifeStageDefinition('Adult'),
    },
    behaviors: {'feeding': 'Feeding'},
  ),
);

void main() {
  test('behavior changes update the journal without adding activity', () async {
    // Count notifications and writes separately. The overlay should refresh on
    // transitions while repeated reports leave both the UI and storage alone
    const specimen = woodlandStickInsect;
    var saves = 0;
    final journal = SpecimenJournal(
      specimen: specimen,
      persist: (_) async => saves++,
    );
    addTearDown(journal.dispose);
    var updates = 0;
    journal.addListener(() => updates++);
    final observedAt = DateTime.utc(2026, 11, 17);
    BehaviorChanged behavior(String id) => BehaviorChanged(
      specimenId: specimen.id,
      stageId: journal.stageId,
      recordedAt: observedAt,
      behaviorId: id,
    );

    expect(journal.observe(behavior('climbing')), isTrue);
    expect(journal.behaviorLabel, 'Climbing');
    expect(journal.observe(behavior('climbing')), isFalse);
    expect(journal.observe(behavior('resting')), isTrue);
    expect(journal.behaviorLabel, 'Resting');
    expect(updates, 2);
    expect(journal.recentActivity, isEmpty);
    await journal.save();
    expect(saves, 0);
  });

  test('learned facts outlive the bounded activity list', () async {
    String? snapshot;
    const specimen = woodlandStickInsect;
    final journal = SpecimenJournal(
      specimen: specimen,
      persist: (value) async => snapshot = value,
    );
    addTearDown(journal.dispose);
    final observedAt = DateTime.utc(2026, 11, 17);

    journal.observe(
      DiscoveryObserved(
        specimenId: specimen.id,
        stageId: journal.stageId,
        recordedAt: observedAt,
        id: 'visitedLeafLitter',
        description: 'Explores leaf litter as well as branches.',
        activityMessage: 'Reached the leaf litter',
      ),
    );
    expect(journal.recentActivity.single.message, 'Reached the leaf litter');

    // Push the original entry beyond the cap. Equal timestamps also show that
    // the log keeps observation order when events share a timestamp
    for (var i = 0; i <= SpecimenJournal.entryLimit; i++) {
      journal.observe(
        DiscoveryObserved(
          specimenId: specimen.id,
          stageId: journal.stageId,
          recordedAt: observedAt,
          id: 'fact-$i',
          description: 'Discovery $i',
          activityMessage: 'Observed $i',
        ),
      );
    }
    // Wait for queued writes before using the last snapshot as a cold start
    await journal.save();

    final restored = SpecimenJournal(specimen: specimen, snapshot: snapshot);
    addTearDown(restored.dispose);
    expect(restored.recentActivity, hasLength(SpecimenJournal.entryLimit));
    expect(restored.recentActivity.first.message, 'Observed 20');
    expect(restored.recentActivity.last.message, 'Observed 1');
    expect(
      restored.facts,
      contains('Explores leaf litter as well as branches.'),
    );
  });

  test('the woodland migration preserves discoveries and timestamps', () {
    // Include the old timer fields to exercise a save from before their removal
    final snapshot = migrateWoodlandJournal('''
{
  "branchSeconds": 42.5,
  "groundSeconds": 11,
  "restSeconds": 7,
  "facts": {"visitedLeafLitter": "Explores leaf litter as well as branches."},
  "activity": [
    {"message": "Reached the leaf litter", "recordedAt": "2026-11-17T10:00:00.000Z"}
  ]
}
''');
    final journal = SpecimenJournal(
      specimen: woodlandStickInsect,
      snapshot: snapshot,
    );
    addTearDown(journal.dispose);
    expect(journal.stageId, 'adult');
    expect(journal.behaviorLabel, isNull);
    expect(journal.facts.single, 'Explores leaf litter as well as branches.');
    expect(
      journal.recentActivity.single.recordedAt,
      DateTime.utc(2026, 11, 17, 10),
    );
  });

  test('one journal follows a caterpillar through metamorphosis', () async {
    String? snapshot;
    final journal = SpecimenJournal(
      specimen: _caterpillar,
      persist: (value) async => snapshot = value,
    );
    addTearDown(journal.dispose);
    final at = DateTime.utc(2026, 11, 17);
    FoodEaten food(
      String stage,
      String id,
      String name, {
      String? specimenId,
    }) => FoodEaten(
      specimenId: specimenId ?? _caterpillar.id,
      stageId: stage,
      recordedAt: at,
      foodId: id,
      foodName: name,
    );
    LifeStageChanged stageChange(String from, String to) => LifeStageChanged(
      specimenId: _caterpillar.id,
      stageId: from,
      recordedAt: at,
      nextStageId: to,
    );

    // Guard both the species' transition rules and the journal's specimen filter
    expect(journal.observe(stageChange('larva', 'adult')), isFalse);
    expect(
      journal.observe(food('larva', 'leaf', 'Leaf', specimenId: 'other')),
      isFalse,
    );
    expect(journal.observe(food('larva', 'leaf', 'Leaf')), isTrue);
    expect(journal.observe(food('larva', 'leaf', 'Leaf')), isTrue);
    expect(journal.observe(stageChange('larva', 'pupa')), isTrue);
    // A delayed larval observation must never count toward the pupa's diet
    expect(journal.observe(food('larva', 'leaf', 'Leaf')), isFalse);
    expect(journal.observe(stageChange('pupa', 'adult')), isTrue);
    expect(journal.observe(food('adult', 'nectar', 'Nectar')), isTrue);
    expect(
      journal.observe(
        MorphIdentified(
          specimenId: _caterpillar.id,
          stageId: 'adult',
          recordedAt: at,
          morphId: 'dappled',
          label: 'Dappled',
        ),
      ),
      isTrue,
    );
    await journal.save();

    final restored = SpecimenJournal(
      specimen: _caterpillar,
      snapshot: snapshot,
    );
    addTearDown(restored.dispose);
    expect(restored.specimen.id, _caterpillar.id);
    expect(restored.stageId, 'adult');
    expect(restored.stagesSeen, ['larva', 'pupa', 'adult']);
    expect(restored.foodEatenIn('larva')['leaf']?.count, 2);
    expect(restored.foodEatenIn('pupa'), isEmpty);
    expect(restored.foodEatenIn('adult').keys, ['nectar']);
    expect(restored.morphs, ['Dappled']);
    expect(
      restored.recentActivity.where(
        (entry) => entry.message == 'Ate Leaf · Larva',
      ),
      hasLength(1),
    );
  });

  testWidgets(
    'a closed journal records the walk and opens with activity collapsed',
    (tester) async {
      tester.view.physicalSize = const Size(420, 760);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final journal = SpecimenJournal(
        specimen: woodlandStickInsect,
        persist: (_) async {},
      );
      addTearDown(journal.dispose);
      await tester.pumpWidget(SanctuaryApp(journal: journal));
      await tester.pump(const Duration(milliseconds: 16));
      expect(find.text('Specimen journal'), findsNothing);
      expect(journal.recentActivity, isEmpty);

      // Advance until the insect reaches its floor rest, independent of the
      // exact timing of the outbound walk
      for (
        var frame = 0;
        frame < 200 &&
            !journal.facts.contains('Has rested on the enclosure floor.');
        frame++
      ) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(journal.behaviorLabel, 'Resting');
      expect(journal.recentActivity.first.message, 'Reached the leaf litter');

      // Tap the resting insect's hit area for the fixed 420 × 760 viewport
      await tester.tapAt(const Offset(354, 595));
      await tester.pump(const Duration(milliseconds: 60));
      expect(find.text('Specimen journal'), findsOneWidget);
      expect(find.text('Adult'), findsOneWidget);
      expect(find.text('Resting'), findsOneWidget);
      expect(
        find.text('Explores leaf litter as well as branches.'),
        findsOneWidget,
      );
      expect(find.text('Reached the leaf litter'), findsNothing);

      await tester.tap(find.text('Recent activity'));
      await tester.pump();
      // Give the tile time to expand before checking its rendered entry
      await tester.pump(const Duration(milliseconds: 220));
      expect(find.text('Reached the leaf litter'), findsOneWidget);

      await tester.tap(find.text('Close journal'));
      await tester.pump();
      expect(find.text('Specimen journal'), findsNothing);

      // A fresh overlay starts collapsed while the recorded activity survives
      await tester.tapAt(const Offset(354, 595));
      await tester.pump(const Duration(milliseconds: 60));
      expect(find.text('Recent activity'), findsOneWidget);
      expect(find.text('Reached the leaf litter'), findsNothing);
    },
  );

  testWidgets('a hungry insect feeds from the shrub without input', (
    tester,
  ) async {
    final journal = SpecimenJournal(specimen: woodlandStickInsect);
    addTearDown(journal.dispose);
    await tester.pumpWidget(SanctuaryApp(journal: journal));
    await tester.pump(const Duration(milliseconds: 16));

    for (var frame = 0; frame < 45; frame++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(journal.behaviorLabel, 'Feeding');
    expect(find.text('Specimen journal'), findsNothing);
    expect(journal.foodEatenIn('adult'), isEmpty);

    // Let the insect finish while the journal is closed, then give the
    // simulation another moment to catch accidental duplicate records
    for (var frame = 0; frame < 25; frame++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(journal.foodEatenIn('adult')['bramble-leaf']?.count, 1);
    expect(journal.recentActivity.single.message, 'Ate Bramble leaf · Adult');
  });
}
