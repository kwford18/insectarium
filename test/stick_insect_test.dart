import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:insect_sanctuary/specimen.dart';
import 'package:insect_sanctuary/specimen_journal.dart';
import 'package:insect_sanctuary/stick_insect.dart';
import 'package:insect_sanctuary/woodland_feeding.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('all six feet rest on the soil line after the walk', () async {
    final journal = SpecimenJournal(specimen: woodlandStickInsect);
    addTearDown(journal.dispose);
    // A horizontal route isolates foot height from the real scene's curves.
    // The viewport gives unit scale and the long tick finishes the scripted walk
    final insect =
        StickInsect(
            trailPath: (_) => (
              path: ui.Path()
                ..moveTo(20, 500)
                ..lineTo(380, 500),
              groundStart: 140,
            ),
            journal: journal,
            onObserve: () {},
          )
          ..onGameResize(Vector2(400, 760))
          ..update(12);

    // Render just the insect so alpha on the soil line comes from a foot stroke
    final recorder = ui.PictureRecorder();
    insect.render(ui.Canvas(recorder));
    final picture = recorder.endRecording();
    final image = await picture.toImage(400, 760);
    addTearDown(picture.dispose);
    addTearDown(image.dispose);
    final pixels = (await image.toByteData())!;

    // Sample the row just above y=500, allowing one neighboring column and a
    // small alpha tolerance for antialiasing at each expected foot position
    for (final x in [296, 304, 311, 333, 340, 348]) {
      final covered = [
        x - 1,
        x,
        x + 1,
      ].any((column) => pixels.getUint8((499 * 400 + column) * 4 + 3) > 30);
      expect(covered, isTrue, reason: 'No foot contact near x=$x');
    }
  });

  test('the insect rests on the branch, visits the floor, and climbs back', () {
    final journal = SpecimenJournal(specimen: woodlandStickInsect);
    addTearDown(journal.dispose);
    final feeding = WoodlandFeeding();
    addTearDown(feeding.dispose);
    final insect = StickInsect(
      trailPath: (_) => (
        path: ui.Path()
          ..moveTo(20, 500)
          ..lineTo(380, 500),
        groundStart: 140,
      ),
      journal: journal,
      onObserve: () {},
      feeding: feeding,
    )..onGameResize(Vector2(400, 760));

    insect.update(4);
    expect(journal.behaviorLabel, 'Resting');
    expect(journal.recentActivity, isEmpty);
    insect.update(2);
    expect(journal.behaviorLabel, 'Climbing');
    insect.update(6);
    expect(journal.behaviorLabel, 'Resting');
    expect(journal.recentActivity.single.message, 'Reached the leaf litter');

    // A serving offered on the floor visit waits at the branch station
    feeding.offerLeaf();
    insect.update(7);
    expect(journal.behaviorLabel, 'Climbing');
    expect(feeding.hasLeaf, isTrue);
    expect(journal.foodEatenIn('adult'), isEmpty);
    insect.update(1);
    expect(journal.behaviorLabel, 'Resting');
    // The original branch hit area is reachable again after the return walk
    expect(insect.containsLocalPoint(Vector2(80, 473)), isTrue);
    expect(journal.recentActivity, hasLength(1));

    insect.update(1);
    expect(journal.behaviorLabel, 'Feeding');
    insect.update(1);
    expect(feeding.hasLeaf, isFalse);
    expect(journal.foodEatenIn('adult')['bramble-leaf']?.count, 1);
  });
}
