import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/events.dart';

import 'specimen_journal.dart';
import 'specimen_observation.dart';

/// Animates the woodland stick insect along an enclosure-supplied route
///
/// Body position and foot placement use the same path so the gait stays
/// attached to the branch and follows its transition onto the floor
class StickInsect extends Component with TapCallbacks {
  StickInsect({
    required this.trailPath,
    required this.journal,
    required this.onObserve,
  });

  /// Builds a continuous contour in scene coordinates for the current viewport
  ///
  /// The ground offset is measured along the curve from its first point and
  /// gives both the behavior logic and the gait the same surface boundary
  final ({ui.Path path, double groundStart}) Function(Vector2 size) trailPath;

  /// Receives behavior transitions and discoveries even while its view is closed
  final SpecimenJournal journal;

  /// Lets the game decide how to present the journal when the insect is tapped
  final void Function() onObserve;

  // Lengths and speed are authored for a 400-unit short side. Resize scales
  // both by the same factor to keep stride size and pace proportional
  static const _stride = 30.0;
  // A stance longer than half a cycle gives the two tripods overlapping contact
  static const _stanceFraction = 0.64;
  static const _startDelay = 0.8;
  static const _walkSpeed = 50.0;
  static const _ink = ui.Color(0xFF513523);
  static const _pigment = ui.Color(0xFFB98751);
  // The tap area includes the thin legs and antennae so the body is easy to select
  static const _tapBounds = ui.Rect.fromLTRB(-46, -20, 56, 36);

  ui.PathMetric? _trail;
  double _scale = 1.0;
  double _start = 0.0;
  double _groundStart = 0.0;
  double _walkDistance = 0.0;
  double _elapsed = 0.0;
  String? _reportedBehavior;

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
    // A whole final stride leaves the two tripods at phases 0 and 0.5, both
    // inside the stance interval. A partial stride can freeze a foot mid-swing
    _walkDistance = ((trail.length - 2 * margin) / stride).floor() * stride;
    // Center the walk to leave room for foot placement at both ends
    _start = (trail.length - _walkDistance) / 2;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_trail == null || dt <= 0) return;

    final previousTravel = _travel;
    _elapsed += dt;
    final travel = _travel;
    // Detect crossings between samples so a long frame can still see the insect
    // reach the floor and finish the walk in a single update
    final wasOnGround = _start + previousTravel >= _groundStart;
    final onGround = _start + travel >= _groundStart;
    final moving = travel > 0 && travel < _walkDistance;
    final behavior = moving ? (onGround ? 'walking' : 'climbing') : 'resting';
    final reachedGround = onGround && !wasOnGround;
    final restedOnGround =
        onGround && !moving && previousTravel < _walkDistance;
    // Report transitions and discoveries without sending events every frame
    if (_reportedBehavior == behavior && !reachedGround && !restedOnGround) {
      return;
    }

    final specimenId = journal.specimen.id;
    final stageId = journal.stageId;
    final now = DateTime.now();

    if (_reportedBehavior != behavior) {
      _reportedBehavior = behavior;
      journal.observe(
        BehaviorChanged(
          specimenId: specimenId,
          stageId: stageId,
          recordedAt: now,
          behaviorId: behavior,
        ),
      );
    }
    if (reachedGround) {
      journal.observe(
        DiscoveryObserved(
          specimenId: specimenId,
          stageId: stageId,
          recordedAt: now,
          id: 'visitedLeafLitter',
          description: 'Explores leaf litter as well as branches.',
          activityMessage: 'Reached the leaf litter',
        ),
      );
    }
    if (restedOnGround) {
      // Keep this as a learned fact. The earlier floor arrival already has a log entry
      journal.observe(
        DiscoveryObserved(
          specimenId: specimenId,
          stageId: stageId,
          recordedAt: now,
          id: 'restedOnGround',
          description: 'Has rested on the enclosure floor.',
        ),
      );
    }
  }

  @override
  bool containsLocalPoint(Vector2 point) {
    final trail = _trail;
    if (trail == null) return false;

    final (body, forward, _) = _pose(trail);
    // Undo the body's translation and scale, then project onto its forward and
    // down axes. The same local tap bounds work at every angle along the trail
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
    // Draw feet in scene coordinates because their anchors are sampled from the
    // route. Draw the body over the hips using a local, right-facing silhouette
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

  // This prototype has one timed traversal. Clamping keeps travel at zero
  // during the starting delay and at full distance after the walk finishes
  double get _travel {
    final duration = _walkDistance / (_walkSpeed * _scale);
    if (duration == 0) return 0;
    return _walkDistance *
        _ease(((_elapsed - _startDelay) / duration).clamp(0.0, 1.0));
  }

  (ui.Offset, ui.Offset, double) _pose(ui.PathMetric trail) {
    final travel = _travel;
    // Distance drives the gait so the legs slow down with the eased body motion.
    // Two bobs per stride follow the two alternating sets of feet
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
    final footDistance =
        _start + (anchor + reach + _ease(swing) * _stride) * _scale;
    final footTangent = _tangentAt(trail, footDistance);
    final lift = math.sin(swing * math.pi) * 10;
    final branchGrip = side == 0 ? 6.0 : -2.0;
    // Blend out the branch grip near the floor so both sides settle on the soil
    final onBranch = ((_groundStart - footDistance) / (9 * _scale)).clamp(
      0.0,
      1.0,
    );
    final gripHeight = branchGrip * onBranch;
    final foot =
        footTangent.position +
        _up(footTangent.vector) * ((gripHeight + lift) * _scale);
    final hip = body + forward * ((leg * 12 - 11) * _scale);
    // Offset each knee along the body to give the three pairs distinct profiles
    final knee =
        ui.Offset.lerp(hip, foot, 0.44)! +
        forward * (((leg - 1) * 8 + (side == 0 ? 5 : -4)) * _scale);

    final legPath = ui.Path()
      ..moveTo(hip.dx, hip.dy)
      ..lineTo(knee.dx, knee.dy)
      ..lineTo(foot.dx, foot.dy);
    canvas.drawPath(legPath, paint);
  }

  // The tail sits on the negative x side and the head on the positive x side.
  // A shared vertical wash carries the same highlight and shadow into the head
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
    // Use elapsed time here so the antennae keep moving during rests
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
    // Feet can reach beyond the body's travel range near either end of the route
    return trail.getTangentForOffset(distance.clamp(0.0, trail.length))!;
  }

  // In a y-down canvas, a right-facing tangent gives an upward normal
  static ui.Offset _up(ui.Offset forward) => ui.Offset(forward.dy, -forward.dx);

  // Smoothstep gives zero slope at both ends of travel and each foot swing
  static double _ease(double t) => t * t * (3 - 2 * t);
}
