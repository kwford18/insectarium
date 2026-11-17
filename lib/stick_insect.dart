import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/events.dart';

import 'specimen_journal.dart';

class StickInsect extends Component with TapCallbacks {
  StickInsect({
    required this.trailPath,
    required this.journal,
    required this.onObserve,
  });

  final ({ui.Path path, double groundStart}) Function(Vector2 size) trailPath;
  final SpecimenJournal journal;
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
  double _groundStart = 0.0;
  double _walkDistance = 0.0;
  double _elapsed = 0.0;

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    if (size.x <= 0 || size.y <= 0) {
      _trail = null;
      return;
    }

    final route = trailPath(size);
    final trail = route.path.computeMetrics().firstOrNull;
    _trail = trail;
    if (trail == null) return;

    _groundStart = route.groundStart;
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
    if (_trail == null) return;

    _elapsed += dt;
    final travel = _travel;
    final onGround = _start + travel >= _groundStart;
    final moving = travel > 0 && travel < _walkDistance;
    journal.observe(
      dt,
      location: onGround
          ? SpecimenLocation.leafLitter
          : SpecimenLocation.branches,
      activity: moving
          ? (onGround ? SpecimenActivity.walking : SpecimenActivity.climbing)
          : SpecimenActivity.resting,
    );
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

  double get _travel {
    final duration = _walkDistance / (_walkSpeed * _scale);
    if (duration == 0) return 0;
    return _walkDistance *
        _ease(((_elapsed - _startDelay) / duration).clamp(0.0, 1.0));
  }

  (ui.Offset, ui.Offset, double) _pose(ui.PathMetric trail) {
    final travel = _travel;
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
    final footDistance =
        _start + (anchor + reach + _ease(swing) * _stride) * _scale;
    final footTangent = _tangentAt(trail, footDistance);
    final lift = math.sin(swing * math.pi) * 10;
    final branchGrip = side == 0 ? 6.0 : -2.0;
    final onBranch = ((_groundStart - footDistance) / (9 * _scale)).clamp(
      0.0,
      1.0,
    );
    final gripHeight = branchGrip * onBranch;
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
      ..quadraticBezierTo(-32, -2, -23, -3.9)
      ..quadraticBezierTo(-16, -5.3, -9, -4.1)
      ..quadraticBezierTo(-5, -3, 0, -3.6)
      ..quadraticBezierTo(10, -3.7, 18, -2.5)
      ..lineTo(22.5, -2.1)
      ..lineTo(23, 1.4)
      ..quadraticBezierTo(14, 3, 5, 2.8)
      ..quadraticBezierTo(-4, 3.8, -11, 3.2)
      ..quadraticBezierTo(-25, 5, -39, 0)
      ..close();
    final fill = ui.Paint()
      ..shader = ui.Gradient.linear(
        const ui.Offset(0, -4),
        const ui.Offset(0, 4),
        [const ui.Color(0xFFD6AF73), _pigment, const ui.Color(0xFF8D603D)],
        const [0, 0.46, 1],
      );
    final line = ui.Paint()
      ..color = _ink
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = ui.StrokeCap.round;
    canvas.drawPath(body, fill);
    canvas.drawPath(body, line);
    final head = ui.Path()
      ..moveTo(21, -2.4)
      ..quadraticBezierTo(23, -4.5, 27, -3.5)
      ..lineTo(30.5, -1.8)
      ..quadraticBezierTo(31.2, 0, 29.2, 1.6)
      ..lineTo(26.7, 2.4)
      ..quadraticBezierTo(22.5, 3, 21, 0.9)
      ..close();
    canvas.drawPath(head, fill);
    line.strokeWidth = 0.85;
    canvas.drawPath(head, line);
    canvas.drawOval(
      const ui.Rect.fromLTWH(26.1, -2.7, 2.3, 1.8),
      ui.Paint()..color = const ui.Color(0xFF493321),
    );

    line.color = const ui.Color(0xA0735033);
    for (final joint in [-29.0, -22.0, -15.0, -7.0, 9.0]) {
      canvas.drawLine(ui.Offset(joint, -2.4), ui.Offset(joint + 1, 2.5), line);
    }

    line.color = const ui.Color(0xFF735033);
    final feel = math.sin(_elapsed * 2.5) * 3;
    final antennae = ui.Path()
      ..moveTo(28.5, -2.5)
      ..quadraticBezierTo(33, -6, 38, -9)
      ..quadraticBezierTo(46, -12, 51, -12 + feel)
      ..moveTo(30, -1)
      ..quadraticBezierTo(35, 0, 40, -3)
      ..quadraticBezierTo(47, -6, 54, -4 - feel);
    canvas.drawPath(antennae, line);
  }

  static ui.Tangent _tangentAt(ui.PathMetric trail, double distance) {
    return trail.getTangentForOffset(distance.clamp(0.0, trail.length))!;
  }

  static ui.Offset _up(ui.Offset forward) => ui.Offset(forward.dy, -forward.dx);

  static double _ease(double t) => t * t * (3 - 2 * t);
}
