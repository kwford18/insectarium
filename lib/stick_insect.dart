import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/events.dart';

import 'specimen_journal.dart';
import 'specimen_observation.dart';
import 'stick_insect_appetite.dart';
import 'stick_insect_art.dart';
import 'stick_insect_walk.dart';
import 'woodland_feeding.dart';
import 'woodland_leaf.dart';

/// Animates the woodland stick insect along an enclosure-supplied route
///
/// Body position and foot placement use the same path so the gait stays
/// attached to the branch and follows its transition onto the floor
class StickInsect extends Component with TapCallbacks {
  StickInsect({
    required this.trailPath,
    required this.journal,
    required this.onObserve,
    this.feeding,
  });

  /// Builds a continuous contour in scene coordinates for the current viewport
  ///
  /// The ground offset is measured along the curve from its first point and
  /// gives both the behavior logic and the gait the same surface boundary
  final ({ui.Path path, double groundStart}) Function(Vector2 size) trailPath;

  /// Receives observations even while its view is closed
  final SpecimenJournal journal;

  /// Lets the game decide how to present the journal when the insect is tapped
  final void Function() onObserve;

  /// Supplies the optional leaf at this insect's branch rest point
  final WoodlandFeeding? feeding;

  static const _stride = StickInsectWalk.strideLength;
  // The tap area includes the thin legs and antennae so the body is easy to select
  static const _tapBounds = ui.Rect.fromLTRB(-46, -20, 56, 36);

  ui.PathMetric? _trail;
  double _scale = 1.0;
  double _start = 0.0;
  double _groundStart = 0.0;
  int _routeStrides = 0;
  double _elapsed = 0.0;
  String? _reportedBehavior;
  final _walk = StickInsectWalk();
  final _appetite = StickInsectAppetite();
  final _sprigArt = WoodlandSprigArt();
  ui.Tangent? _sprigAnchor;

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
    _routeStrides = ((trail.length - 2 * margin) / stride).floor();
    // Center the walk to leave room for foot placement at both ends
    _start = (trail.length - _routeStrides * stride) / 2;
    // Put the sprig just ahead of the branch rest where the mouth can reach it
    _sprigAnchor = feeding == null
        ? null
        : _tangentAt(trail, _start + 18 * _scale);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_trail == null || dt <= 0) return;

    final previous = _walk.sample(_routeStrides);
    _elapsed += dt;
    final feeding = this.feeding;
    final meal = _appetite.advance(
      dt,
      leafInReach: previous.atBranchRest && (feeding?.hasLeaf ?? false),
    );
    // Let the existing walk bring a hungry insect back to the sprig. Once a
    // meal starts, hold the planted branch pose until it finishes
    final mealCompleted = meal.finished && (feeding?.eatLeaf() ?? false);
    if (!meal.feeding) _walk.advance(dt);
    final current = _walk.sample(_routeStrides);
    final wasOnGround =
        _routeDistance(previous.strides, previous.returning) >= _groundStart;
    final onGround =
        _routeDistance(current.strides, current.returning) >= _groundStart;
    final behavior = meal.feeding && !mealCompleted
        ? 'feeding'
        : current.moving
        ? (onGround ? 'walking' : 'climbing')
        : 'resting';
    final reachedGround = onGround && !wasOnGround;
    final restedOnGround =
        onGround && !current.moving && (previous.moving || reachedGround);
    // Report transitions and discoveries without sending events every frame
    if (_reportedBehavior == behavior &&
        !reachedGround &&
        !restedOnGround &&
        !mealCompleted) {
      return;
    }

    final specimenId = journal.specimen.id;
    final stageId = journal.stageId;
    final now = DateTime.now();

    if (mealCompleted) {
      journal.observe(
        FoodEaten(
          specimenId: specimenId,
          stageId: stageId,
          recordedAt: now,
          foodId: WoodlandFeeding.foodId,
          foodName: WoodlandFeeding.foodName,
        ),
      );
    }
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

    final walk = _walk.sample(_routeStrides);
    final (body, forward) = _pose(trail, walk.strides, walk.returning);
    // Undo the body's translation and scale, then project onto its forward and
    // down axes. The same local tap bounds work at every angle along the trail
    final relative = (ui.Offset(point.x, point.y) - body) / _scale;
    final along = relative.dx * forward.dx + relative.dy * forward.dy;
    final down = relative.dy * forward.dx - relative.dx * forward.dy;
    return _tapBounds.contains(
      ui.Offset(walk.returning ? -along : along, down),
    );
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

    final walk = _walk.sample(_routeStrides);
    final (body, forward) = _pose(trail, walk.strides, walk.returning);
    final anchor = _sprigAnchor;
    final feeding = this.feeding;
    if (anchor != null && feeding != null) {
      _sprigArt.draw(canvas, anchor, _scale, feeding.eatenLeaves);
    }
    StickInsectArt.draw(
      canvas,
      trail: trail,
      body: body,
      forward: forward,
      strides: walk.strides,
      returning: walk.returning,
      scale: _scale,
      groundStart: _groundStart,
      routeDistance: _routeDistance,
      elapsed: _elapsed,
    );
  }

  @override
  void onRemove() {
    _sprigArt.dispose();
    super.onRemove();
  }

  // Gait distances start at the departure point of each leg. Path metrics
  // always count from the branch, so subtract from the far end on the return
  double _routeDistance(double strides, bool returning) {
    return _start +
        (returning ? _routeStrides - strides : strides) * _stride * _scale;
  }

  (ui.Offset, ui.Offset) _pose(
    ui.PathMetric trail,
    double strides,
    bool returning,
  ) {
    // Distance drives the gait so the legs slow down with the eased body motion.
    // Two bobs per stride follow the two alternating sets of feet
    final tangent = _tangentAt(trail, _routeDistance(strides, returning));
    final forward = tangent.vector;
    final bob = (1 - math.cos(strides * math.pi * 4)) * 0.6;
    final body = tangent.position + _up(forward) * ((27 + bob) * _scale);
    return (body, forward);
  }

  static ui.Tangent _tangentAt(ui.PathMetric trail, double distance) {
    return trail.getTangentForOffset(distance.clamp(0.0, trail.length))!;
  }

  // In a y-down canvas, a right-facing tangent gives an upward normal
  static ui.Offset _up(ui.Offset forward) => ui.Offset(forward.dy, -forward.dx);
}
