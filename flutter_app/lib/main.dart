import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'field_note.dart';
import 'stick_insect.dart';

const _fieldNote = 'fieldNote';

void main() {
  final game = FlameGame();
  game.addAll([
    WoodlandWash(),
    StickInsect(
      branchPath: woodlandBranch,
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

class WoodlandWash extends Component {
  ui.Picture? _background;

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (size.x <= 0 || size.y <= 0) return;

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    canvas.drawColor(const ui.Color(0xFFF4E9D2), ui.BlendMode.src);

    final random = math.Random(37);
    final scale = math.min(size.x, size.y);
    for (var i = 0; i < 24; i++) {
      final center = ui.Offset(
        random.nextDouble() * size.x,
        (0.35 + random.nextDouble() * 0.75) * size.y,
      );
      final radius = scale * (0.12 + random.nextDouble() * 0.28);
      final pigment = i.isEven
          ? const ui.Color.fromARGB(69, 3, 153, 83)
          : const ui.Color(0x4DBC9848);

      final paint = ui.Paint()
        ..shader = ui.Gradient.radial(center, radius, [
          pigment,
          pigment.withValues(alpha: 0),
        ]);
      canvas.drawCircle(center, radius, paint);
    }

    final branch = woodlandBranch(size);
    final branchPaint = ui.Paint()
      ..style = ui.PaintingStyle.stroke
      ..strokeCap = ui.StrokeCap.round
      ..strokeWidth = scale * 0.045
      ..color = const ui.Color(0xFF77553E);
    canvas.drawPath(branch, branchPaint);
    canvas.drawPath(
      branch.shift(ui.Offset(0, -scale * 0.009)),
      branchPaint
        ..strokeWidth = scale * 0.014
        ..color = const ui.Color(0xAACEA472),
    );

    _background?.dispose();
    _background = recorder.endRecording();
  }

  @override
  void render(ui.Canvas canvas) {
    final background = _background;
    if (background != null) canvas.drawPicture(background);
  }

  @override
  void onRemove() {
    _background?.dispose();
    _background = null;
    super.onRemove();
  }
}

ui.Path woodlandBranch(Vector2 size) {
  return ui.Path()
    ..moveTo(size.x * 0.08, size.y * 0.72)
    ..cubicTo(
      size.x * 0.28,
      size.y * 0.67,
      size.x * 0.63,
      size.y * 0.49,
      size.x * 0.92,
      size.y * 0.47,
    );
}
