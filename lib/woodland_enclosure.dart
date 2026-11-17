import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';

/// Paints the static woodland scene in layers around the specimen
class WoodlandEnclosure extends Component {
  WoodlandEnclosure({this.foreground = false})
    : super(priority: foreground ? 1 : -1);

  final bool foreground;
  ui.Picture? _picture;

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (size.x <= 0 || size.y <= 0) return;

    // Cache the drawing until the layout changes to avoid tracing it each frame
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    final layout = _WoodlandLayout(size);
    final scale = math.min(size.x, size.y);

    if (foreground) {
      _paintSprigs(canvas, layout.upperBranch, scale, [0.30, 0.70], 17);
      _paintSprigs(canvas, layout.stem, scale, [0.32], 63);
    } else {
      _paintWash(canvas, size, scale);
      _paintUnderstory(canvas, size, scale);
      _paintFloor(canvas, layout, size, scale);
      _paintWood(
        canvas,
        layout.stem,
        scale,
        startWidth: 0.032,
        endWidth: 0.057,
      );
      _paintWood(
        canvas,
        layout.crownBranch,
        scale,
        startWidth: 0.004,
        endWidth: 0.031,
      );
      _paintWood(
        canvas,
        layout.upperBranch,
        scale,
        startWidth: 0.003,
        endWidth: 0.023,
      );
      _paintRoots(canvas, layout.root, scale);
      _paintSprigs(canvas, layout.upperBranch, scale, [0.14, 0.46, 0.83], 29);
      _paintSprigs(canvas, layout.crownBranch, scale, [
        0.12,
        0.36,
        0.61,
        0.84,
      ], 43);
    }

    _picture?.dispose();
    _picture = recorder.endRecording();
  }

  void _paintRoots(ui.Canvas canvas, ui.Offset root, double scale) {
    final x = root.dx;
    final y = root.dy;
    final right = ui.Path()
      ..moveTo(x - scale * 0.025, y - scale * 0.007)
      ..quadraticBezierTo(
        x + scale * 0.041,
        y + scale * 0.01,
        x + scale * 0.09,
        y + scale * 0.026,
      );
    final left = ui.Path()
      ..moveTo(x - scale * 0.022, y)
      ..quadraticBezierTo(
        x - scale * 0.064,
        y + scale * 0.012,
        x - scale * 0.11,
        y + scale * 0.042,
      );
    _paintWood(canvas, right, scale, startWidth: 0.037, endWidth: 0.002);
    _paintWood(canvas, left, scale, startWidth: 0.024, endWidth: 0.002);
  }

  void _paintWash(ui.Canvas canvas, Vector2 size, double scale) {
    canvas.drawColor(const ui.Color(0xFFF4E9D2), ui.BlendMode.src);
    // Fixed seeds keep the procedural artwork reproducible on resize
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

  void _paintWood(
    ui.Canvas canvas,
    ui.Path path,
    double scale, {
    required double startWidth,
    required double endWidth,
  }) {
    final curve = path.computeMetrics().firstOrNull;
    if (curve == null) return;
    final left = <ui.Offset>[];
    final right = <ui.Offset>[];
    final grain = ui.Path();
    // Offset the sampled centerline on both sides to taper the branch silhouette
    for (var i = 0; i <= 30; i++) {
      final t = i / 30;
      final tangent = curve.getTangentForOffset(t * curve.length)!;
      final normal = _normal(tangent.vector);
      final halfWidth = scale * ui.lerpDouble(startWidth, endWidth, t)! * 0.5;
      final variation = 1 + 0.10 * math.sin(i * 1.31);
      left.add(tangent.position + normal * (halfWidth * variation));
      right.add(tangent.position - normal * halfWidth);

      final highlight = tangent.position + normal * (halfWidth * 0.43);
      if (i == 0) {
        grain.moveTo(highlight.dx, highlight.dy);
      } else {
        grain.lineTo(highlight.dx, highlight.dy);
      }
    }
    final bark = ui.Path()..addPolygon([...left, ...right.reversed], true);
    canvas.drawPath(bark, ui.Paint()..color = const ui.Color(0xFF816044));
    canvas.drawPath(
      grain,
      ui.Paint()
        ..style = ui.PaintingStyle.stroke
        ..strokeCap = ui.StrokeCap.round
        ..strokeWidth = scale * 0.004
        ..color = const ui.Color(0xAAC49A64),
    );
  }

  void _paintSprigs(
    ui.Canvas canvas,
    ui.Path branch,
    double scale,
    List<double> sites,
    int seed,
  ) {
    final curve = branch.computeMetrics().firstOrNull;
    if (curve == null) return;
    final random = math.Random(seed);
    final stem = ui.Paint()
      ..color = const ui.Color(0xC56B7350)
      ..strokeWidth = scale * 0.003
      ..strokeCap = ui.StrokeCap.round;
    final pigment = ui.Paint();
    for (var i = 0; i < sites.length; i++) {
      final tangent = curve.getTangentForOffset(sites[i] * curve.length)!;
      final start = tangent.position;
      final side = i.isEven ? 1.0 : -1.0;
      final tip =
          start -
          tangent.vector * (scale * 0.045) +
          _normal(tangent.vector) *
              (side * scale * (0.075 + random.nextDouble() * 0.05));
      canvas.drawLine(start, tip, stem);
      final direction = (tip - start) / (tip - start).distance;
      final normal = _normal(direction);
      for (var leaf = 0; leaf < 4; leaf++) {
        final base = ui.Offset.lerp(start, tip, 0.30 + leaf * 0.22)!;
        final turn = leaf.isEven ? 1.0 : -1.0;
        final length = scale * (0.042 + random.nextDouble() * 0.038);
        final end = base + (direction * 0.66 + normal * turn * 0.74) * length;
        final mid = ui.Offset.lerp(base, end, 0.48)!;
        final bend = _normal(end - base) * (0.25 + random.nextDouble() * 0.15);
        final left = mid + bend;
        final right = mid - bend * 0.74;
        final blade = ui.Path()
          ..moveTo(base.dx, base.dy)
          ..quadraticBezierTo(left.dx, left.dy, end.dx, end.dy)
          ..quadraticBezierTo(right.dx, right.dy, base.dx, base.dy)
          ..close();
        pigment.color = random.nextBool()
            ? const ui.Color(0xD0758B53)
            : const ui.Color(0xB6A4A55C);
        canvas.drawPath(blade, pigment);
        canvas.drawLine(base, ui.Offset.lerp(base, end, 0.72)!, stem);
      }
    }
  }

  static ui.Offset _normal(ui.Offset direction) =>
      ui.Offset(direction.dy, -direction.dx);

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

/// Returns the current route and the distance along it where the floor begins
({ui.Path path, double groundStart}) woodlandTrail(Vector2 size) {
  final layout = _WoodlandLayout(size);
  return (path: layout.trail, groundStart: layout.groundStart);
}

/// Shares the surface curves between the enclosure art and the walking route
class _WoodlandLayout {
  _WoodlandLayout(Vector2 size) {
    final w = size.x;
    final h = size.y;
    final join = ui.Offset(w * 0.46, h * 0.49);
    root = ui.Offset(w * 0.70, h * 0.81);

    upperBranch = ui.Path()
      ..moveTo(w * 0.12, h * 0.32)
      ..cubicTo(w * 0.24, h * 0.34, w * 0.36, h * 0.41, join.dx, join.dy);
    stem = ui.Path()
      ..moveTo(join.dx, join.dy)
      ..cubicTo(w * 0.57, h * 0.58, w * 0.50, root.dy, root.dx, root.dy);
    crownBranch = ui.Path()
      ..moveTo(w * 0.78, h * 0.30)
      ..cubicTo(w * 0.63, h * 0.36, w * 0.44, h * 0.39, join.dx, join.dy);
    final groundTrail = ui.Path()
      ..moveTo(root.dx, root.dy)
      ..cubicTo(w * 0.81, root.dy, w * 0.91, h * 0.82, w, h * 0.825);

    groundSurface = ui.Path()
      ..moveTo(0, h * 0.835)
      ..cubicTo(w * 0.19, h * 0.80, w * 0.47, root.dy, root.dx, root.dy)
      ..extendWithPath(groundTrail, ui.Offset.zero);

    // The continuous contour lets the gait sample across both joins by distance
    trail = ui.Path.from(upperBranch)..extendWithPath(stem, ui.Offset.zero);
    groundStart = trail.computeMetrics().firstOrNull?.length ?? 0;
    trail.extendWithPath(groundTrail, ui.Offset.zero);
  }

  late final ui.Path upperBranch;
  late final ui.Offset root;
  late final ui.Path crownBranch;
  late final ui.Path stem;
  late final ui.Path groundSurface;
  late final ui.Path trail;
  late final double groundStart;
}
