import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:insect_sanctuary/specimen.dart';
import 'package:insect_sanctuary/specimen_journal.dart';
import 'package:insect_sanctuary/stick_insect.dart';
import 'package:insect_sanctuary/stick_insect_trail.dart';
import 'package:insect_sanctuary/stick_insect_walk.dart';
import 'package:insect_sanctuary/woodland_enclosure.dart';
import 'package:insect_sanctuary/woodland_sprig.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the insect cruises at a steady pace between short speed ramps', () {
    final walk = StickInsectWalk()
      ..configure(10, crownStrides: null, relocatedReturnStop: null);
    void tick(double seconds) => walk.advance(
      seconds,
      chooseCrown: (_) => false,
      chooseReturnStop: () => null,
    );

    tick(5);
    final start = walk.sample().strides;
    tick(0.1);
    final rampDistance = (walk.sample().strides - start) * 30;
    expect(rampDistance, greaterThan(0));
    expect(rampDistance, lessThan(4));

    tick(0.9);
    final first = walk.sample().strides;
    tick(1);
    final second = walk.sample().strides;
    tick(2);
    final third = walk.sample().strides;
    expect((second - first) * 30, closeTo(40, 0.001));
    expect((third - second) * 30, closeTo(80, 0.001));
  });

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
    insect.update(8.5);
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

    insect.update(3);
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
    for (var frame = 0; frame < 270; frame++) {
      insect.update(0.1);
    }

    expect(upper.feeding.eatenLeaves, 1);
    expect(middle.feeding.eatenLeaves, 1);
    expect(lower.feeding.hasLeaf, isFalse);
    expect(journal.foodEatenIn('adult')['bramble-leaf']?.count, 2);
  });

  test('the insect alternates branches through a shared floor stop', () {
    final journal = SpecimenJournal(specimen: woodlandStickInsect);
    addTearDown(journal.dispose);
    final size = Vector2(420, 760);
    final insect = StickInsect(
      trailPath: woodlandTrail,
      crownTrailPath: woodlandCrownTrail,
      journal: journal,
      onObserve: () {},
    )..onGameResize(size);
    final upperRoute = woodlandTrail(size);
    final crownRoute = woodlandCrownTrail(size);
    final upper = StickInsectTrail(
      metric: upperRoute.path.computeMetrics().first,
      groundStart: upperRoute.groundStart,
      scale: 1.05,
    );
    final crown = StickInsectTrail(
      metric: crownRoute.path.computeMetrics().first,
      groundStart: crownRoute.groundStart,
      scale: 1.05,
      sharedFloorMargin: upper.floorMargin,
    );
    final floorGap =
        upper.tangentAt(upper.end).position -
        crown.tangentAt(crown.end).position;
    expect(floorGap.distance, lessThan(0.2));

    Vector2 restPoint(StickInsectTrail trail) {
      final tangent = trail.tangentAt(trail.start);
      final up = ui.Offset(tangent.vector.dy, -tangent.vector.dx);
      final body = tangent.position + up * (27 * trail.scale);
      return Vector2(body.dx, body.dy);
    }

    bool reachRest(Vector2 point) {
      // Advance in short ticks to catch the real floor turn and branch rest
      for (var frame = 0; frame < 240; frame++) {
        insect.update(0.2);
        if (journal.behaviorLabel == 'Resting' &&
            insect.containsLocalPoint(point)) {
          return true;
        }
      }
      return false;
    }

    final upperRest = restPoint(upper);
    expect(insect.containsLocalPoint(upperRest), isTrue);
    expect(reachRest(restPoint(crown)), isTrue);
    expect(reachRest(upperRest), isTrue);
    expect(journal.recentActivity.single.message, 'Reached the leaf litter');
  });

  test('the insect returns to the branch with food and can eat on the crown', () {
    final journal = SpecimenJournal(specimen: woodlandStickInsect);
    addTearDown(journal.dispose);
    final upper = WoodlandSprig();
    final crown = WoodlandSprig();
    for (var leaf = 0; leaf < 4; leaf++) {
      crown.feeding.eatLeaf();
    }
    final insect = StickInsect(
      trailPath: woodlandTrail,
      crownTrailPath: woodlandCrownTrail,
      journal: journal,
      onObserve: () {},
      feedingSprigs: [upper],
      crownSprig: crown,
    )..onGameResize(Vector2(420, 760));

    bool advanceUntil(bool Function() reached) {
      for (var frame = 0; frame < 250; frame++) {
        insect.update(0.2);
        if (reached()) return true;
      }
      return false;
    }

    // A bare crown makes the insect revisit the upper branch on its first trip
    expect(advanceUntil(() => upper.feeding.eatenLeaves == 2), isTrue);
    expect(crown.feeding.hasLeaf, isFalse);

    upper.feeding
      ..eatLeaf()
      ..eatLeaf();
    crown.feeding.replenish();
    // Switching which branch has food gives the crown the next meal
    expect(advanceUntil(() => crown.feeding.eatenLeaves == 1), isTrue);
    expect(journal.foodEatenIn('adult')['bramble-leaf']?.count, 3);
  });
}
