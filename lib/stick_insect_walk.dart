/// The current stick-insect route schedule, measured in complete strides
///
/// It rests on the upper branch, walks down the existing trail, rests on the
/// floor, and climbs back. See docs/architecture/stick-insect-behavior.md for
/// the planned behavior work
class StickInsectWalk {
  /// Distance of one complete gait cycle at the reference viewport scale
  static const strideLength = 30.0;
  static const _walkSpeed = 50.0;
  static const _branchRest = 5.0;
  static const _floorRest = 5.0;
  static const _sprigRest = 0.8;

  int _strideCount = 0;
  bool _hasReturnStops = false;
  double _phase = 0;
  int? _returnStop;

  double get _walkTime => _strideCount * strideLength / _walkSpeed;
  double get _returnStart => _branchRest + _walkTime + _floorRest;
  double get _returnAllowance => _hasReturnStops ? _sprigRest : 0;
  double get _cycleTime => _returnStart + _walkTime + _returnAllowance;

  /// The chosen feeding stop on the uphill leg, measured from the upper end
  int? get returnStop => _returnStop;

  /// Travel time from the floor to a candidate stop on the uphill leg
  double secondsToReturnStop(int stop) =>
      (_strideCount - stop) * strideLength / _walkSpeed;

  /// Rescales the route clock and keeps an active meal at its relocated stop
  void configure(
    int strideCount, {
    required bool hasReturnStops,
    required int? relocatedReturnStop,
  }) {
    if (_strideCount == strideCount &&
        _hasReturnStops == hasReturnStops &&
        _returnStop == relocatedReturnStop) {
      return;
    }
    final restingAt = sample().feedingStop;
    final progress = _phase / _cycleTime;
    if (_strideCount != strideCount || _hasReturnStops != hasReturnStops) {
      _strideCount = strideCount;
      _hasReturnStops = hasReturnStops;
      _phase = progress * _cycleTime;
    }
    _returnStop = relocatedReturnStop;
    if (restingAt == 0 && _phase >= _branchRest) {
      _phase = _branchRest / 2;
    } else if (restingAt != null &&
        restingAt > 0 &&
        relocatedReturnStop != null) {
      _phase =
          _returnStart +
          secondsToReturnStop(relocatedReturnStop) +
          _sprigRest / 2;
    }
  }

  /// Advances the route, choosing a sprig once as the insect leaves the floor
  ///
  /// Reserve the same return time even when there is no stop. The route can
  /// then change its destination at departure without shifting the floor rest
  void advance(double seconds, int? Function() chooseReturnStop) {
    if (_strideCount == 0) return;
    final previous = _phase;
    final next = previous + seconds;
    final wrapped = next >= _cycleTime;
    _phase = next % _cycleTime;
    if (wrapped) _returnStop = null;
    if (_hasReturnStops &&
        _phase >= _returnStart &&
        (wrapped || previous < _returnStart)) {
      _returnStop = chooseReturnStop();
    }
  }

  /// Returns travel from the current leg's start and its direction
  ///
  /// Reversing starts a new gait at stride zero. Each end of the route is a
  /// whole stride away so a rest always starts with both tripods planted.
  /// Feeding stops are counted from the upper end, even on the return leg
  ({double strides, bool returning, bool moving, int? feedingStop}) sample() {
    final strideCount = _strideCount;
    if (strideCount == 0) {
      return (strides: 0, returning: false, moving: false, feedingStop: 0);
    }
    // The caller scales distance and speed together, so timing uses unscaled units
    final walkTime = _walkTime;
    final floorArrival = _branchRest + walkTime;
    final returnStart = _returnStart;
    final phase = _phase;
    if (phase < _branchRest) {
      return (strides: 0, returning: false, moving: false, feedingStop: 0);
    }
    if (phase < floorArrival) {
      final progress = (phase - _branchRest) / walkTime;
      return (
        strides: strideCount * _ease(progress),
        returning: false,
        moving: true,
        feedingStop: null,
      );
    }
    if (phase < returnStart) {
      return (
        strides: strideCount.toDouble(),
        returning: false,
        moving: false,
        feedingStop: null,
      );
    }
    final returnTime = phase - returnStart;
    final stop = _returnStop;
    if (stop != null) {
      // Split the climb into two eased walks so the insect slows into the
      // sprig and resumes from a planted gait phase after the stop
      final beforeSprig = strideCount - stop;
      final timeToSprig = secondsToReturnStop(stop);
      if (returnTime < timeToSprig) {
        return (
          strides: beforeSprig * _ease(returnTime / timeToSprig),
          returning: true,
          moving: true,
          feedingStop: null,
        );
      }
      final afterRest = returnTime - timeToSprig - _sprigRest;
      if (afterRest < 0) {
        return (
          strides: beforeSprig.toDouble(),
          returning: true,
          moving: false,
          feedingStop: stop,
        );
      }
      final remainingTime = walkTime - timeToSprig;
      return (
        strides: beforeSprig + stop * _ease(afterRest / remainingTime),
        returning: true,
        moving: true,
        feedingStop: null,
      );
    }
    final progress = returnTime / (walkTime + _returnAllowance);
    return (
      strides: strideCount * _ease(progress),
      returning: true,
      moving: true,
      feedingStop: null,
    );
  }

  // Smoothstep gives the body zero speed at the start and end of each walk
  static double _ease(double t) => t * t * (3 - 2 * t);
}
