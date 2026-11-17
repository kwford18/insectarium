import 'dart:math' as math;
import 'dart:ui' as ui;

import 'stick_insect_walk.dart';

/// Draws the stick insect's body and the legs that follow the enclosure path
class StickInsectArt {
  static const _stride = StickInsectWalk.strideLength;
  // A stance longer than half a cycle gives the two tripods overlapping contact
  static const _stanceFraction = 0.64;
  static const _outline = ui.Color(0xFF513523);
  static const _pigment = ui.Color(0xFFB98751);

  /// Paints a pose using path coordinates for the feet and local body artwork
  static void draw(
    ui.Canvas canvas, {
    required ui.PathMetric trail,
    required ui.Offset body,
    required ui.Offset forward,
    required double strides,
    required bool returning,
    required double scale,
    required double groundStart,
    required double Function(double strides, bool returning) routeDistance,
    required double elapsed,
  }) {
    // Draw the legs first so the body covers their attachment points
    final legPaint = ui.Paint()
      ..style = ui.PaintingStyle.stroke
      ..strokeCap = ui.StrokeCap.round
      ..strokeJoin = ui.StrokeJoin.round
      ..strokeWidth = 1.7 * scale;
    for (var side = 0; side < 2; side++) {
      legPaint.color = side == 0 ? const ui.Color(0xFF947553) : _outline;
      for (var leg = 0; leg < 3; leg++) {
        _drawLeg(
          canvas,
          trail,
          body,
          forward,
          strides,
          returning,
          side,
          leg,
          legPaint,
          scale,
          groundStart,
          routeDistance,
        );
      }
    }

    canvas.save();
    canvas.translate(body.dx, body.dy);
    canvas.rotate(math.atan2(forward.dy, forward.dx));
    // Mirror the head and tail for the return while retaining the surface up axis
    canvas.scale(returning ? -scale : scale, scale);
    _drawBody(canvas, elapsed);
    canvas.restore();
  }

  static void _drawLeg(
    ui.Canvas canvas,
    ui.PathMetric trail,
    ui.Offset body,
    ui.Offset forward,
    double strideCount,
    bool returning,
    int side,
    int leg,
    ui.Paint paint,
    double scale,
    double groundStart,
    double Function(double strides, bool returning) routeDistance,
  ) {
    // Alternate tripods so adjacent legs and opposing legs use opposite phases
    final phaseOffset = (side + leg).isEven ? 0.0 : 0.5;
    final cycle = strideCount + phaseOffset;
    final wholeSteps = cycle.floor();
    final phase = cycle - wholeSteps;
    final swing = ((phase - _stanceFraction) / (1 - _stanceFraction)).clamp(
      0.0,
      1.0,
    );

    // The integer cycle chooses a fixed path anchor through stance. During
    // swing the foot advances one stride and lifts in an arc that returns to
    // zero at both ends, where it joins the adjacent stance positions
    final anchor = (wholeSteps - phaseOffset + _stanceFraction / 2) * _stride;
    final reach = (leg - 1) * 22 + (side == 0 ? -4 : 3);
    final footDistance = routeDistance(
      (anchor + reach) / _stride + _ease(swing),
      returning,
    );
    final footTangent = _tangentAt(trail, footDistance);
    final lift = math.sin(swing * math.pi) * 10;
    final branchGrip = side == 0 ? 6.0 : -2.0;
    // Blend out the branch grip near the floor so both sides settle on the soil
    final onBranch = ((groundStart - footDistance) / (9 * scale)).clamp(
      0.0,
      1.0,
    );
    final gripHeight = branchGrip * onBranch;
    final foot =
        footTangent.position +
        _up(footTangent.vector) * ((gripHeight + lift) * scale);
    final heading = returning ? -forward : forward;
    final hip = body + heading * ((leg * 12 - 11) * scale);
    // Offset each knee along the body to give the three pairs distinct profiles
    final knee =
        ui.Offset.lerp(hip, foot, 0.44)! +
        heading * (((leg - 1) * 8 + (side == 0 ? 5 : -4)) * scale);

    final legPath = ui.Path()
      ..moveTo(hip.dx, hip.dy)
      ..lineTo(knee.dx, knee.dy)
      ..lineTo(foot.dx, foot.dy);
    canvas.drawPath(legPath, paint);
  }

  // The tail sits on the negative x side and the head on the positive x side.
  // A shared vertical wash carries the same highlight and shadow into the head
  static void _drawBody(ui.Canvas canvas, double elapsed) {
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
      ..color = _outline
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
    // Use elapsed time here so the antennae keep moving during rests
    final feel = math.sin(elapsed * 2.5) * 3;
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
    // Feet can reach beyond the route near the ends of a small viewport
    return trail.getTangentForOffset(distance.clamp(0.0, trail.length))!;
  }

  static ui.Offset _up(ui.Offset tangent) => ui.Offset(tangent.dy, -tangent.dx);

  // Smoothstep joins the forward swing smoothly to fixed stance positions
  static double _ease(double t) => t * t * (3 - 2 * t);
}
