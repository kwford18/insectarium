import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:insect_sanctuary/specimen.dart';
import 'package:insect_sanctuary/specimen_journal.dart';
import 'package:insect_sanctuary/stick_insect.dart';
import 'package:insect_sanctuary/woodland_sprig.dart';

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

  test('a hungry insect can eat at the lower sprig on its return', () {
    final journal = SpecimenJournal(specimen: woodlandStickInsect);
    addTearDown(journal.dispose);
    final upperSprig = WoodlandSprig();
    final lowerSprig = WoodlandSprig(uphill: true);
    final feeding = upperSprig.feeding;
    final lowerFeeding = lowerSprig.feeding;
    final insect = StickInsect(
      trailPath: (_) => (
        path: ui.Path()
          ..moveTo(20, 500)
          ..lineTo(380, 500),
        groundStart: 140,
      ),
      journal: journal,
      onObserve: () {},
      feedingSprigs: [upperSprig, lowerSprig],
    )..onGameResize(Vector2(400, 760));

    insect.update(4);
    expect(journal.behaviorLabel, 'Resting');
    expect(journal.recentActivity, isEmpty);
    insect.update(1);
    expect(journal.behaviorLabel, 'Feeding');
    expect(feeding.hasBite, isTrue);
    expect(feeding.eatenLeaves, 0);
    expect(journal.recentActivity, isEmpty);
    insect.update(0.6);
    expect(feeding.eatenLeaves, 1);
    expect(feeding.hasBite, isFalse);

    insect.update(2);
    expect(journal.behaviorLabel, 'Climbing');
    insect.update(6);
    expect(journal.behaviorLabel, 'Resting');
    expect(journal.recentActivity.first.message, 'Reached the leaf litter');

    // The second hunger interval runs out during the trip, away from food
    insect.update(6);
    expect(journal.behaviorLabel, 'Climbing');
    expect(feeding.eatenLeaves, 1);
    expect(lowerFeeding.eatenLeaves, 0);
    insect.update(0.75);
    expect(journal.behaviorLabel, 'Resting');
    insect.update(1);
    expect(journal.behaviorLabel, 'Feeding');
    insect.update(1);
    expect(feeding.eatenLeaves, 1);
    expect(lowerFeeding.eatenLeaves, 1);
    expect(journal.foodEatenIn('adult')['bramble-leaf']?.count, 2);
    expect(journal.recentActivity, hasLength(2));

    insect.update(2);
    expect(journal.behaviorLabel, 'Resting');
    // The original branch hit area is reachable again after the lower sprig stop
    expect(insect.containsLocalPoint(Vector2(80, 473)), isTrue);
  });

  test('the insect passes an empty lower sprig to eat from the middle', () {
    final journal = SpecimenJournal(specimen: woodlandStickInsect);
    addTearDown(journal.dispose);
    final upper = WoodlandSprig();
    final middle = WoodlandSprig(uphill: true);
    final lower = WoodlandSprig(uphill: true);
    for (var leaf = 0; leaf < 4; leaf++) {
      lower.feeding.eatLeaf();
    }
    final insect = StickInsect(
      trailPath: (_) => (
        path: ui.Path()
          ..moveTo(20, 500)
          ..lineTo(380, 500),
        groundStart: 140,
      ),
      journal: journal,
      onObserve: () {},
      feedingSprigs: [upper, middle, lower],
    )..onGameResize(Vector2(400, 760));

    // Advance through a real sequence of departure and arrival ticks so the
    // route must account for hunger that develops during the uphill climb
    for (var frame = 0; frame < 240; frame++) {
      insect.update(0.1);
    }

    expect(upper.feeding.eatenLeaves, 1);
    expect(middle.feeding.eatenLeaves, 1);
    expect(lower.feeding.hasLeaf, isFalse);
    expect(journal.foodEatenIn('adult')['bramble-leaf']?.count, 2);
  });
}
