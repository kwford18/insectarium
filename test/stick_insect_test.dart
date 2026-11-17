import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:insect_sanctuary/specimen.dart';
import 'package:insect_sanctuary/specimen_journal.dart';
import 'package:insect_sanctuary/stick_insect.dart';

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
          ..update(20);

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
}
