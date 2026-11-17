import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'field_note.dart';
import 'stick_insect.dart';
import 'woodland_enclosure.dart';

const _fieldNote = 'fieldNote';

void main() {
  final game = FlameGame();
  game.addAll([
    WoodlandEnclosure(),
    StickInsect(
      trailPath: woodlandTrail,
      onObserve: () => game.overlays.add(_fieldNote),
    ),
  ]);

  runApp(
    MaterialApp(
      title: 'Insect Sanctuary',
      debugShowCheckedModeBanner: false,
      home: GameWidget(
        game: game,
        overlayBuilderMap: {
          _fieldNote: (_, _) =>
              FieldNote(onClose: () => game.overlays.remove(_fieldNote)),
        },
      ),
    ),
  );
}
