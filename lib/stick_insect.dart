import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/events.dart';

import 'specimen_journal.dart';
import 'specimen_observation.dart';
import 'stick_insect_appetite.dart';
import 'stick_insect_art.dart';
import 'stick_insect_trail.dart';
import 'stick_insect_walk.dart';
import 'woodland_feeding.dart';
import 'woodland_sprig.dart';

/// Animates the woodland stick insect along an enclosure-supplied route
///
/// Body position and foot placement use the same path so the gait stays
/// attached to the branch and follows its transition onto the floor
class StickInsect extends Component with TapCallbacks {
  StickInsect({
    required this.trailPath,
    this.crownTrailPath,
    required this.journal,
    required this.onObserve,
    this.feedingSprigs = const [],
  });

  /// Builds a continuous contour in scene coordinates for the current viewport
  ///
  /// The ground offset is measured along the curve from its first point and
  /// gives both the behavior logic and the gait the same surface boundary
  final ({ui.Path path, double groundStart}) Function(Vector2 size) trailPath;

  /// Optional crown contour, including the distance at which it joins the stem
  final ({ui.Path path, double groundStart, double stemStart}) Function(
    Vector2 size,
  )?
  crownTrailPath;

  /// Receives observations even while its view is closed
  final SpecimenJournal journal;

  /// Lets the game decide how to present the journal when the insect is tapped
  final void Function() onObserve;

  /// Woodland sprigs in trail order, beginning at the upper branch rest point
  final List<WoodlandSprig> feedingSprigs;

  static const _stride = StickInsectWalk.strideLength;
  // The tap area includes the thin legs and antennae so the body is easy to select
  static const _tapBounds = ui.Rect.fromLTRB(-46, -20, 56, 36);

  StickInsectTrail? _trail;
  StickInsectTrail? _crownTrail;
  double _crownStemStart = 0;
  double _elapsed = 0.0;
  String? _reportedBehavior;
  final _walk = StickInsectWalk();
  final _appetite = StickInsectAppetite();
  final _feedingStops = <int, WoodlandSprig>{};

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    final selectedSprig = _feedingStops[_walk.returnStop];
    for (final sprig in feedingSprigs) {
      sprig.place(null, 1);
    }
    _trail = null;
    _crownTrail = null;
    if (size.x <= 0 || size.y <= 0) {
      return;
    }

    final route = trailPath(size);
    final metric = route.path.computeMetrics().firstOrNull;
    if (metric == null) return;
    final scale = math.min(size.x, size.y) / 400;
    final trail = StickInsectTrail(
      metric: metric,
      groundStart: route.groundStart,
      scale: scale,
    );
    _trail = trail;

    final crown = crownTrailPath?.call(size);
    final crownMetric = crown?.path.computeMetrics().firstOrNull;
    if (crown != null && crownMetric != null) {
      final candidate = StickInsectTrail(
        metric: crownMetric,
        groundStart: crown.groundStart,
        scale: scale,
        sharedFloorMargin: trail.floorMargin,
      );
      // A narrow layout may have no reachable ground or usable crown endpoint
      if (trail.end > trail.groundStart &&
          candidate.end > candidate.groundStart &&
          candidate.strides > 0 &&
          candidate.start < crown.stemStart) {
        _crownTrail = candidate;
        _crownStemStart = crown.stemStart;
      }
    }
    _placeFeedingStops(trail, selectedSprig);
  }

  void _placeFeedingStops(
    StickInsectTrail trail,
    WoodlandSprig? selectedSprig,
  ) {
    _feedingStops.clear();
    final stride = _stride * trail.scale;
    final branchStrides = (trail.groundStart - trail.start) / stride;
    int? relocatedStop;
    for (final (index, sprig) in feedingSprigs.indexed) {
      // Spread the uphill stops across the wood. Align each to a whole stride
      // and leave duplicate or unreachable spots out on short layouts
      final fraction = index == 0 ? 0.0 : index / (feedingSprigs.length - 1);
      final branchStop = (branchStrides * (2 / 3) * fraction).round();
      final stop = index == 0 ? 0 : trail.strides - branchStop;
      if (index > 0 &&
          (branchStop <= 0 ||
              branchStop >= branchStrides ||
              stop <= 0 ||
              _feedingStops.containsKey(stop))) {
        continue;
      }
      _feedingStops[stop] = sprig;
      if (index > 0 && identical(sprig, selectedSprig)) relocatedStop = stop;
      // The anchor goes ahead of the mouth along its approach direction
      final mouthReach = (index == 0 ? 18 : -18) * trail.scale;
      sprig.place(
        trail.tangentAt(trail.start + branchStop * stride + mouthReach),
        trail.scale,
      );
    }
    _walk.configure(
      trail.strides,
      crownStrides: _crownTrail?.strides,
      hasReturnStops: _feedingStops.length > 1,
      relocatedReturnStop: _walk.returnsToCrown
          ? _sharedStop(relocatedStop)
          : relocatedStop,
    );
  }

  int? _chooseReturnStop() {
    // Stops are inserted from top to bottom. The lowest stocked sprig is
    // the first one it can reach if it will be hungry by the time it gets there
    int? choice;
    for (final entry in _feedingStops.entries) {
      if (entry.key > 0 &&
          (!_walk.returnsToCrown || _sharedStop(entry.key) != null) &&
          entry.value.feeding.hasLeaf &&
          _appetite.hungryWithin(_walk.secondsToReturnStop(entry.key))) {
        choice = entry.key;
      }
    }
    return choice;
  }

  // A sprig beyond the fork belongs to the upper route. Its position is
  // reachable on a crown trip only when both contours still share the wood
  int? _sharedStop(int? stop) {
    final crownTrail = _crownTrail;
    if (stop == null ||
        crownTrail == null ||
        crownTrail.distanceAt(stop.toDouble(), true) - 18 * crownTrail.scale <
            _crownStemStart) {
      return null;
    }
    return stop;
  }

  @override
  void update(double dt) {
    super.update(dt);
    final upperTrail = _trail;
    if (upperTrail == null || dt <= 0) return;

    final previous = _walk.sample();
    _elapsed += dt;
    final availableSprig = _feedingStops[previous.feedingStop]?.feeding;
    final meal = _appetite.advance(
      dt,
      leafInReach: availableSprig?.hasLeaf ?? false,
    );
    // Hold the walking clock during a meal so the feet stay planted until the
    // selected sprig loses a leaf
    if (meal.bitLeaf) availableSprig?.biteLeaf();
    final mealCompleted = meal.finished && (availableSprig?.eatLeaf() ?? false);
    if (!meal.feeding) _walk.advance(dt, _chooseReturnStop);
    final current = _walk.sample();
    final previousTrail = previous.crown ? _crownTrail! : upperTrail;
    final currentTrail = current.crown ? _crownTrail! : upperTrail;
    final wasOnGround =
        previousTrail.distanceAt(previous.strides, previous.returning) >=
        previousTrail.groundStart;
    final onGround =
        currentTrail.distanceAt(current.strides, current.returning) >=
        currentTrail.groundStart;
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
    final walk = _walk.sample();
    final trail = walk.crown ? _crownTrail : _trail;
    if (trail == null) return false;
    final (body, forward) = _pose(trail, walk.strides, walk.returning);
    // Undo the body's translation and scale, then project onto its forward and
    // down axes. The same local tap bounds work at every angle along the trail
    final relative = (ui.Offset(point.x, point.y) - body) / trail.scale;
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
    final walk = _walk.sample();
    final trail = walk.crown ? _crownTrail : _trail;
    if (trail == null) return;
    final (body, forward) = _pose(trail, walk.strides, walk.returning);
    StickInsectArt.draw(
      canvas,
      trail: trail.metric,
      body: body,
      forward: forward,
      strides: walk.strides,
      returning: walk.returning,
      scale: trail.scale,
      groundStart: trail.groundStart,
      routeDistance: trail.distanceAt,
      elapsed: _elapsed,
    );
  }

  (ui.Offset, ui.Offset) _pose(
    StickInsectTrail trail,
    double strides,
    bool returning,
  ) {
    // Distance drives the gait so the legs slow down with the eased body motion.
    // Two bobs per stride follow the two alternating sets of feet
    final tangent = trail.tangentAt(trail.distanceAt(strides, returning));
    final forward = tangent.vector;
    final bob = (1 - math.cos(strides * math.pi * 4)) * 0.6;
    final body = tangent.position + _up(forward) * ((27 + bob) * trail.scale);
    return (body, forward);
  }

  // In a y-down canvas, a right-facing tangent gives an upward normal
  static ui.Offset _up(ui.Offset forward) => ui.Offset(forward.dy, -forward.dx);
}
