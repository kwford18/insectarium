import 'dart:ui' show Offset, Size;

import 'package:flutter_test/flutter_test.dart';
import 'package:insect_sanctuary/main.dart';
import 'package:insect_sanctuary/specimen_journal.dart';

void main() {
  test('learned facts and metrics outlive the bounded activity list', () async {
    String? snapshot;
    final journal = SpecimenJournal(persist: (value) async => snapshot = value);
    addTearDown(journal.dispose);

    journal.observe(
      2,
      location: SpecimenLocation.leafLitter,
      activity: SpecimenActivity.walking,
    );
    journal.observe(
      3,
      location: SpecimenLocation.leafLitter,
      activity: SpecimenActivity.resting,
    );
    expect(journal.groundSeconds, 3);
    expect(journal.recentActivity.single.message, 'Reached the leaf litter');

    for (var i = 0; i <= SpecimenJournal.entryLimit; i++) {
      journal.learn('fact-$i', 'Discovery $i', activity: 'Observed $i');
    }
    await journal.save();

    final restored = SpecimenJournal(snapshot: snapshot);
    addTearDown(restored.dispose);
    expect(restored.recentActivity, hasLength(SpecimenJournal.entryLimit));
    expect(restored.recentActivity.first.message, 'Observed 20');
    expect(restored.recentActivity.last.message, 'Observed 1');
    expect(
      restored.facts,
      contains('Explores leaf litter as well as branches.'),
    );
    expect(restored.facts, contains('Has rested on the enclosure floor.'));
    expect(restored.branchSeconds, 2);
    expect(restored.groundSeconds, 3);
  });

  testWidgets(
    'a closed journal records the walk and opens with activity collapsed',
    (tester) async {
      tester.view.physicalSize = const Size(420, 760);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final journal = SpecimenJournal(persist: (_) async {});
      addTearDown(journal.dispose);
      await tester.pumpWidget(SanctuaryApp(journal: journal));
      await tester.pump(const Duration(milliseconds: 16));
      expect(find.text('Specimen journal'), findsNothing);
      expect(journal.recentActivity, isEmpty);

      for (var frame = 0; frame < 115; frame++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      expect(journal.location, SpecimenLocation.leafLitter);
      expect(journal.recentActivity.single.message, 'Reached the leaf litter');

      await tester.tapAt(const Offset(354, 595));
      await tester.pump(const Duration(milliseconds: 60));
      expect(find.text('Specimen journal'), findsOneWidget);
      expect(find.text('Metrics'), findsOneWidget);
      expect(
        find.text('Explores leaf litter as well as branches.'),
        findsOneWidget,
      );
      expect(find.text('Reached the leaf litter'), findsNothing);

      await tester.tap(find.text('Recent activity'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 220));
      expect(find.text('Reached the leaf litter'), findsOneWidget);

      await tester.tap(find.text('Close journal'));
      await tester.pump();
      expect(find.text('Specimen journal'), findsNothing);
    },
  );
}
