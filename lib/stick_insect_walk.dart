/// The current stick-insect route schedule, measured in complete strides
///
/// Each cycle leaves one branch, rests on the shared floor, and chooses
/// where to climb next. The contour only changes at floor rest
/// or after completing a full trip
class StickInsectWalk {
  /// Distance of one complete gait cycle at the reference viewport scale
  static const strideLength = 30.0;
  static const _walkSpeed = 40.0;
  static const _rampSeconds = 0.28;
  static const _branchRest = 5.0;
  static const _floorRest = 5.0;
  static const _sprigRest = 0.8;

  int _strideCount = 0;
  int? _crownStrides;
  bool _startsAtCrown = false;
  bool _returnsToCrown = false;
  double _phase = 0;
  int? _returnStop;

  bool get returnsToCrown => _returnsToCrown;
  int get _outboundStrides => _startsAtCrown ? _crownStrides! : _strideCount;
  int get _returnStrides => returnsToCrown ? _crownStrides! : _strideCount;
  double get _outboundTime => _travelTime(_outboundStrides);
  double get _returnTime {
    final stop = _returnStop;
    return stop == null
        ? _travelTime(_returnStrides)
        : _travelTime(stop) + _sprigRest + _travelTime(_returnStrides - stop);
  }

  double get _returnStart => _branchRest + _outboundTime + _floorRest;
  double get _cycleTime => _returnStart + _returnTime;

  /// The chosen feeding stop measured in strides from the shared floor rest
  int? get returnStop => _returnStop;

  /// Travel time from the floor to a candidate stop on the uphill leg
  double secondsToReturnStop(int stop) => _travelTime(stop);

  /// Rescales the route clock and keeps an active meal at its relocated stop
  void configure(
    int strideCount, {
    required int? crownStrides,
    required int? relocatedReturnStop,
  }) {
    if (_strideCount == strideCount &&
        _crownStrides == crownStrides &&
        _returnStop == relocatedReturnStop) {
      return;
    }
    final restingAt = sample().feedingStop;
    final wasReturning = _phase >= _returnStart;
    final progress = wasReturning
        ? (_phase - _returnStart) / _returnTime
        : _phase / _returnStart;
    _strideCount = strideCount;
    _crownStrides = crownStrides;
    if (crownStrides == null) {
      _startsAtCrown = false;
      _returnsToCrown = false;
    }
    _returnStop = relocatedReturnStop;
    _phase = wasReturning
        ? _returnStart + progress * _returnTime
        : progress * _returnStart;
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

  /// Advances the route and chooses the branch and sprig on departure
  ///
  /// Crossing either boundary preserves leftover time. The length of the
  /// return leg depends on the new destination and any stop along the way
  void advance(
    double seconds, {
    required bool Function(bool startsAtCrown) chooseCrown,
    required int? Function() chooseReturnStop,
  }) {
    if (_strideCount == 0) return;
    while (seconds > 0) {
      final departing = _phase < _returnStart;
      final boundary = departing ? _returnStart : _cycleTime;
      final remaining = boundary - _phase;
      if (seconds < remaining) {
        _phase += seconds;
        return;
      }
      seconds -= remaining;
      if (departing) {
        _phase = boundary;
        _returnsToCrown = _crownStrides != null && chooseCrown(_startsAtCrown);
        _returnStop = chooseReturnStop();
      } else {
        _startsAtCrown = _returnsToCrown;
        _returnStop = null;
        _phase = 0;
      }
    }
  }

  /// Returns travel from the current leg's start and its direction
  ///
  /// Reversing starts a new gait at stride zero. Each end of the route is a
  /// whole stride away so a rest always starts with both tripods planted.
  /// Both contours measure shared feeding stops from their aligned floor rest
  ({double strides, bool returning, bool crown, bool moving, int? feedingStop})
  sample() {
    // The caller scales distance and speed together, so timing uses unscaled units
    final floorArrival = _branchRest + _outboundTime;
    final returnStart = _returnStart;
    final phase = _phase;
    if (_strideCount == 0 || phase < _branchRest) {
      return (
        strides: 0,
        returning: false,
        crown: _startsAtCrown,
        moving: false,
        feedingStop: 0,
      );
    }
    if (phase < floorArrival) {
      return (
        strides: _distanceInStrides(phase - _branchRest, _outboundStrides),
        returning: false,
        crown: _startsAtCrown,
        moving: true,
        feedingStop: null,
      );
    }
    if (phase < returnStart) {
      return (
        strides: _outboundStrides.toDouble(),
        returning: false,
        crown: _startsAtCrown,
        moving: false,
        feedingStop: null,
      );
    }
    final returnTime = phase - returnStart;
    final stop = _returnStop;
    if (stop != null) {
      // Split the climb into two eased walks so the insect slows into the
      // sprig and resumes from a planted gait phase after the stop
      final timeToSprig = secondsToReturnStop(stop);
      if (returnTime < timeToSprig) {
        return (
          strides: _distanceInStrides(returnTime, stop),
          returning: true,
          crown: returnsToCrown,
          moving: true,
          feedingStop: null,
        );
      }
      final afterRest = returnTime - timeToSprig - _sprigRest;
      if (afterRest < 0) {
        return (
          strides: stop.toDouble(),
          returning: true,
          crown: returnsToCrown,
          moving: false,
          feedingStop: stop,
        );
      }
      return (
        strides: stop + _distanceInStrides(afterRest, _returnStrides - stop),
        returning: true,
        crown: returnsToCrown,
        moving: true,
        feedingStop: null,
      );
    }
    return (
      strides: _distanceInStrides(returnTime, _returnStrides),
      returning: true,
      crown: returnsToCrown,
      moving: true,
      feedingStop: null,
    );
  }

  static double _travelTime(int strides) =>
      strides == 0 ? 0 : strides * strideLength / _walkSpeed + _rampSeconds;

  // Integrate a short linear speed ramp at each end and cruise in between.
  // Each ramp covers half the distance a full-speed tick would cover
  static double _distanceInStrides(double seconds, int strides) {
    final rate = _walkSpeed / strideLength;
    final left = _travelTime(strides) - seconds;
    if (seconds < _rampSeconds) {
      return rate * seconds * seconds / (2 * _rampSeconds);
    }
    if (left < _rampSeconds) {
      return strides - rate * left * left / (2 * _rampSeconds);
    }
    return rate * (seconds - _rampSeconds / 2);
  }
}
