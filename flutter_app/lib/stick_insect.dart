import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/events.dart';

class StickInsect extends Component with TapCallbacks {
  StickInsect({required this.trailPath, required this.onObserve});

  final ui.Path Function(Vector2 size) trailPath;
  final void Function() onObserve;

  static const _stride = 30.0;
  static const _stanceFraction = 0.64;
  static const _startDelay = 0.8;
  static const _walkSpeed = 50.0;
  static const _ink = ui.Color(0xFF513523);
  static const _pigment = ui.Color(0xFFB98751);
  static const _tapBounds = ui.Rect.fromLTRB(-46, -20, 56, 36);

  ui.PathMetric? _trail;
  double _scale = 1.0;
  double _start = 0.0;
  double _walkDistance = 0.0;
  double _elapsed = 0.0;

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (size.x <= 0 || size.y <= 0) {
      _trail = null;
      return;
    }

    final trail = trailPath(size).computeMetrics().firstOrNull;
    _trail = trail;
    if (trail == null) return;

    _scale = math.min(size.x, size.y) / 400;
    final stride = _stride * _scale;
    final margin = math.min(55 * _scale, trail.length / 4);
    // A whole number of strides lets all six feet settle at the end.
    _walkDistance = ((trail.length - 2 * margin) / stride).floor() * stride;
    _start = (trail.length - _walkDistance) / 2;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_trail != null) _elapsed += dt;
  }

  @override
  bool containsLocalPoint(Vector2 point) {
    final trail = _trail;
    if (trail == null) return false;

    final (body, forward, _) = _pose(trail);
    final relative = (ui.Offset(point.x, point.y) - body) / _scale;
    final along = relative.dx * forward.dx + relative.dy * forward.dy;
    final down = relative.dy * forward.dx - relative.dx * forward.dy;
    return _tapBounds.contains(ui.Offset(along, down));
  }

  @override
  void onTapUp(TapUpEvent event) {
    super.onTapUp(event);
    onObserve();
  }

  @override
  void render(ui.Canvas canvas) {
    final trail = _trail;
    if (trail == null) return;

    final (body, forward, strideCount) = _pose(trail);
    final legPaint = ui.Paint()
      ..style = ui.PaintingStyle.stroke
      ..strokeCap = ui.StrokeCap.round
      ..strokeJoin = ui.StrokeJoin.round
      ..strokeWidth = 1.7 * _scale;
    for (var side = 0; side < 2; side++) {
      legPaint.color = side == 0 ? const ui.Color(0xFF947553) : _ink;
      for (var leg = 0; leg < 3; leg++) {
        _drawLeg(
          canvas,
          trail,
          body,
          forward,
          strideCount,
          side,
          leg,
          legPaint,
        );
      }
    }

    canvas.save();
    canvas.translate(body.dx, body.dy);
    canvas.rotate(math.atan2(forward.dy, forward.dx));
    canvas.scale(_scale);
    _drawBody(canvas);
    canvas.restore();
  }

  (ui.Offset, ui.Offset, double) _pose(ui.PathMetric trail) {
    final duration = _walkDistance / (_walkSpeed * _scale);
    final progress = duration == 0
        ? 0.0
        : ((_elapsed - _startDelay) / duration).clamp(0.0, 1.0);
    final travel = _walkDistance * _ease(progress);
    final strideCount = travel / (_stride * _scale);
    final tangent = _tangentAt(trail, _start + travel);
    final forward = tangent.vector;
    final bob = (1 - math.cos(strideCount * math.pi * 4)) * 0.6;
    final body = tangent.position + _up(forward) * ((27 + bob) * _scale);
    return (body, forward, strideCount);
  }

  void _drawLeg(
    ui.Canvas canvas,
    ui.PathMetric trail,
    ui.Offset body,
    ui.Offset forward,
    double strideCount,
    int side,
    int leg,
    ui.Paint paint,
  ) {
    final phaseOffset = (side + leg).isEven ? 0.0 : 0.5;
    final cycle = strideCount + phaseOffset;
    final wholeSteps = cycle.floor();
    final phase = cycle - wholeSteps;
    final swing = ((phase - _stanceFraction) / (1 - _stanceFraction)).clamp(
      0.0,
      1.0,
    );

    // Until swing begins, the anchor depends on the step number alone.
    final anchor = (wholeSteps - phaseOffset + _stanceFraction / 2) * _stride;
    final reach = (leg - 1) * 22 + (side == 0 ? -4 : 3);
    final footTangent = _tangentAt(
      trail,
      _start + (anchor + reach + _ease(swing) * _stride) * _scale,
    );
    final lift = math.sin(swing * math.pi) * 10;
    final gripHeight = side == 0 ? 6.0 : -2.0;
    final foot =
        footTangent.position +
        _up(footTangent.vector) * ((gripHeight + lift) * _scale);
    final hip = body + forward * ((leg * 12 - 11) * _scale);
    final knee =
        ui.Offset.lerp(hip, foot, 0.44)! +
        forward * (((leg - 1) * 8 + (side == 0 ? 5 : -4)) * _scale);

    final legPath = ui.Path()
      ..moveTo(hip.dx, hip.dy)
      ..lineTo(knee.dx, knee.dy)
      ..lineTo(foot.dx, foot.dy);
    canvas.drawPath(legPath, paint);
  }

  void _drawBody(ui.Canvas canvas) {
    final body = ui.Path()
      ..moveTo(-39, 0)
      ..quadraticBezierTo(-26, -5, -12, -4)
      ..quadraticBezierTo(0, -3.5, 22, -2.5)
      ..lineTo(24, 1.6)
      ..quadraticBezierTo(-5, 4, -21, 4)
      ..quadraticBezierTo(-32, 3, -39, 0)
      ..close();
    final fill = ui.Paint()..color = _pigment;
    final line = ui.Paint()
      ..color = _ink
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = ui.StrokeCap.round;
    canvas.drawPath(body, fill);
    canvas.drawPath(body, line);
    canvas.drawCircle(const ui.Offset(23, -0.5), 4, fill);
    canvas.drawCircle(const ui.Offset(23, -0.5), 4, line);
    canvas.drawCircle(const ui.Offset(24, -1.5), 1, ui.Paint()..color = _ink);

    line.color = const ui.Color(0xFF735033);
    for (final joint in [-28.0, -21.0, -14.0]) {
      canvas.drawLine(ui.Offset(joint, -1), ui.Offset(joint + 1, 2.7), line);
    }

    final feel = math.sin(_elapsed * 2.5) * 3;
    final antennae = ui.Path()
      ..moveTo(25, -2)
      ..quadraticBezierTo(33, -11, 45, -12 + feel)
      ..moveTo(26, -1)
      ..quadraticBezierTo(36, -5, 49, -4 - feel);
    canvas.drawPath(antennae, line);
  }

  static ui.Tangent _tangentAt(ui.PathMetric trail, double distance) {
    return trail.getTangentForOffset(distance.clamp(0.0, trail.length))!;
  }

  static ui.Offset _up(ui.Offset forward) => ui.Offset(forward.dy, -forward.dx);

  static double _ease(double t) => t * t * (3 - 2 * t);
}
