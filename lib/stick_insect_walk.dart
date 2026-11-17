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
  static const _lowerSprigRest = 0.8;

  double _elapsed = 0;

  /// Advances the route clock. The component holds this clock during feeding
  void advance(double seconds) => _elapsed += seconds;

  /// Returns travel from the current leg's start and its direction
  ///
  /// Reversing starts a new gait at stride zero. Each end of the route is a
  /// whole stride away so a rest always starts with both tripods planted.
  /// Feeding stops are counted from the upper end, even on the return leg
  ({double strides, bool returning, bool moving, int? feedingStop}) sample(
    int strideCount, {
    int? lowerSprigStride,
  }) {
    if (strideCount == 0) {
      return (strides: 0, returning: false, moving: false, feedingStop: 0);
    }
    // The caller scales distance and speed together, so timing uses unscaled units
    final walkTime = strideCount * strideLength / _walkSpeed;
    final floorArrival = _branchRest + walkTime;
    final returnStart = floorArrival + _floorRest;
    final sprigRest = lowerSprigStride == null ? 0.0 : _lowerSprigRest;
    final phase = _elapsed % (returnStart + walkTime + sprigRest);
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
    if (lowerSprigStride != null) {
      // Split the climb into two eased walks so the insect slows into the
      // sprig and resumes from a planted gait phase after the stop
      final beforeSprig = strideCount - lowerSprigStride;
      final timeToSprig = walkTime * beforeSprig / strideCount;
      if (returnTime < timeToSprig) {
        return (
          strides: beforeSprig * _ease(returnTime / timeToSprig),
          returning: true,
          moving: true,
          feedingStop: null,
        );
      }
      final afterRest = returnTime - timeToSprig - sprigRest;
      if (afterRest < 0) {
        return (
          strides: beforeSprig.toDouble(),
          returning: true,
          moving: false,
          feedingStop: lowerSprigStride,
        );
      }
      final remainingTime = walkTime - timeToSprig;
      return (
        strides:
            beforeSprig + lowerSprigStride * _ease(afterRest / remainingTime),
        returning: true,
        moving: true,
        feedingStop: null,
      );
    }
    final progress = returnTime / walkTime;
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
