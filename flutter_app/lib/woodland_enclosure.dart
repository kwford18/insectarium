import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';

class WoodlandEnclosure extends Component {
  ui.Picture? _picture;

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (size.x <= 0 || size.y <= 0) return;

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    final layout = _WoodlandLayout(size);
    final scale = math.min(size.x, size.y);

    _paintWash(canvas, size, scale);
    _paintUnderstory(canvas, size, scale);
    _paintFloor(canvas, layout, size, scale);
    _paintWood(canvas, layout.lowerBranch, scale, 0.060);
    _paintWood(canvas, layout.upperBranch, scale, 0.038);

    _picture?.dispose();
    _picture = recorder.endRecording();
  }

  void _paintWash(ui.Canvas canvas, Vector2 size, double scale) {
    canvas.drawColor(const ui.Color(0xFFF4E9D2), ui.BlendMode.src);
    final random = math.Random(37);
    final paint = ui.Paint();
    for (var i = 0; i < 24; i++) {
      final center = ui.Offset(
        random.nextDouble() * size.x,
        (0.18 + random.nextDouble() * 0.75) * size.y,
      );
      final radius = scale * (0.12 + random.nextDouble() * 0.28);
      final pigment = i.isEven
          ? const ui.Color.fromARGB(69, 3, 153, 83)
          : const ui.Color(0x4DBC9848);
      paint.shader = ui.Gradient.radial(center, radius, [
        pigment,
        pigment.withValues(alpha: 0),
      ]);
      canvas.drawCircle(center, radius, paint);
    }
  }

  void _paintUnderstory(ui.Canvas canvas, Vector2 size, double scale) {
    final stems = [
      (
        ui.Offset(size.x * 0.08, size.y * 0.83),
        ui.Offset(size.x * 0.04, size.y * 0.54),
      ),
      (
        ui.Offset(size.x * 0.88, size.y * 0.83),
        ui.Offset(size.x * 0.93, size.y * 0.48),
      ),
    ];
    final paint = ui.Paint()
      ..color = const ui.Color(0x38536A43)
      ..strokeWidth = scale * 0.004;
    for (final (base, tip) in stems) {
      canvas.drawLine(base, tip, paint);
      for (var index = 1; index < 7; index++) {
        final joint = ui.Offset.lerp(base, tip, index / 7)!;
        final side = index.isEven ? 1.0 : -1.0;
        final length = scale * (0.076 - index * 0.006);
        canvas.save();
        canvas.translate(joint.dx, joint.dy);
        canvas.rotate(-side * 0.62);
        canvas.drawOval(
          ui.Rect.fromCenter(
            center: ui.Offset(side * length * 0.47, 0),
            width: length,
            height: length * 0.42,
          ),
          paint,
        );
        canvas.restore();
      }
    }
  }

  void _paintFloor(
    ui.Canvas canvas,
    _WoodlandLayout layout,
    Vector2 size,
    double scale,
  ) {
    final soil = ui.Path.from(layout.groundSurface)
      ..lineTo(size.x, size.y)
      ..lineTo(0, size.y)
      ..close();
    canvas.drawPath(
      soil,
      ui.Paint()
        ..shader = ui.Gradient.linear(
          ui.Offset(0, size.y * 0.81),
          ui.Offset(0, size.y),
          [const ui.Color(0xFF9E9465), const ui.Color(0xFF62553E)],
        ),
    );

    final random = math.Random(91);
    final leafPaint = ui.Paint();
    for (var i = 0; i < 35; i++) {
      final x = random.nextDouble() * size.x;
      final y = size.y * (0.85 + random.nextDouble() * 0.15);
      final length = scale * (0.01 + random.nextDouble() * 0.027);
      leafPaint.color = i.isEven
          ? const ui.Color(0xAA524833)
          : const ui.Color(0x9FCAB17A);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(random.nextDouble() * math.pi);
      final leaf = ui.Path()
        ..moveTo(-length, 0)
        ..quadraticBezierTo(0, -length * 0.65, length, 0)
        ..quadraticBezierTo(0, length * 0.65, -length, 0)
        ..close();
      canvas.drawPath(leaf, leafPaint);
      canvas.restore();
    }
  }

  void _paintWood(ui.Canvas canvas, ui.Path path, double scale, double width) {
    final paint = ui.Paint()
      ..style = ui.PaintingStyle.stroke
      ..strokeCap = ui.StrokeCap.round
      ..strokeWidth = scale * width
      ..color = const ui.Color(0xFF77553E);
    canvas.drawPath(path, paint);
    canvas.drawPath(
      path.shift(ui.Offset(0, -scale * width * 0.17)),
      paint
        ..strokeWidth = scale * width * 0.37
        ..color = const ui.Color(0xAACEA472),
    );
  }

  @override
  void render(ui.Canvas canvas) {
    final picture = _picture;
    if (picture != null) canvas.drawPicture(picture);
  }

  @override
  void onRemove() {
    _picture?.dispose();
    _picture = null;
    super.onRemove();
  }
}

ui.Path woodlandTrail(Vector2 size) => _WoodlandLayout(size).trail;

/// All three surfaces meet at the exact points used by the walking path.
class _WoodlandLayout {
  _WoodlandLayout(Vector2 size) {
    final w = size.x;
    final h = size.y;
    final join = ui.Offset(w * 0.46, h * 0.49);
    final root = ui.Offset(w * 0.70, h * 0.81);

    upperBranch = ui.Path()
      ..moveTo(w * 0.12, h * 0.32)
      ..cubicTo(w * 0.24, h * 0.34, w * 0.36, h * 0.41, join.dx, join.dy);
    final descendingStem = ui.Path()
      ..moveTo(join.dx, join.dy)
      ..cubicTo(w * 0.57, h * 0.58, w * 0.50, root.dy, root.dx, root.dy);
    lowerBranch = ui.Path()
      ..moveTo(w * 0.78, h * 0.30)
      ..cubicTo(w * 0.63, h * 0.36, w * 0.44, h * 0.39, join.dx, join.dy)
      ..extendWithPath(descendingStem, ui.Offset.zero);
    final groundTrail = ui.Path()
      ..moveTo(root.dx, root.dy)
      ..cubicTo(w * 0.81, root.dy, w * 0.91, h * 0.82, w, h * 0.825);

    groundSurface = ui.Path()
      ..moveTo(0, h * 0.835)
      ..cubicTo(w * 0.19, h * 0.80, w * 0.47, root.dy, root.dx, root.dy)
      ..extendWithPath(groundTrail, ui.Offset.zero);

    trail = ui.Path.from(upperBranch)
      ..extendWithPath(descendingStem, ui.Offset.zero)
      ..extendWithPath(groundTrail, ui.Offset.zero);
  }

  late final ui.Path upperBranch;
  late final ui.Path lowerBranch;
  late final ui.Path groundSurface;
  late final ui.Path trail;
}
