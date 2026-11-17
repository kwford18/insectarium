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

  double _elapsed = 0;

  /// Advances the route clock. The component holds this clock during feeding
  void advance(double seconds) => _elapsed += seconds;

  /// Returns travel from the current leg's start and its direction
  ///
  /// Reversing starts a new gait at stride zero. Each end of the route is a
  /// whole stride away so a rest always starts with both tripods planted
  ({double strides, bool returning, bool moving, bool atBranchRest}) sample(
    int strideCount,
  ) {
    if (strideCount == 0) {
      return (strides: 0, returning: false, moving: false, atBranchRest: true);
    }
    // The caller scales distance and speed together, so timing uses unscaled units
    final walkTime = strideCount * strideLength / _walkSpeed;
    final floorArrival = _branchRest + walkTime;
    final returnStart = floorArrival + _floorRest;
    final phase = _elapsed % (returnStart + walkTime);
    if (phase < _branchRest) {
      return (strides: 0, returning: false, moving: false, atBranchRest: true);
    }
    if (phase < floorArrival) {
      final progress = (phase - _branchRest) / walkTime;
      return (
        strides: strideCount * _ease(progress),
        returning: false,
        moving: true,
        atBranchRest: false,
      );
    }
    if (phase < returnStart) {
      return (
        strides: strideCount.toDouble(),
        returning: false,
        moving: false,
        atBranchRest: false,
      );
    }
    final progress = (phase - returnStart) / walkTime;
    return (
      strides: strideCount * _ease(progress),
      returning: true,
      moving: true,
      atBranchRest: false,
    );
  }

  // Smoothstep gives the body zero speed at the start and end of each walk
  static double _ease(double t) => t * t * (3 - 2 * t);
}
