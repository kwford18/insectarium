import 'dart:math' as math;

/// A brief body sway during a longer rest, independent of the walking gait
class StickInsectSway {
  static const _delay = 0.95;
  static const _duration = 2.6;
  static const _settleDuration = 0.18;

  double _restTime = 0;
  double _settleTime = 0;

  void advance(double seconds, {required bool resting}) {
    if (resting) {
      _restTime += seconds;
      _settleTime = 0;
    } else if (_restTime > 0) {
      // If feeding interrupts the sway, blend the pose back over a few frames
      _settleTime += seconds;
      if (_settleTime >= _settleDuration) {
        _restTime = 0;
        _settleTime = 0;
      }
    }
  }

  /// The body offset in reference units and its angle in radians
  ({double offset, double angle}) sample() {
    final progress = (_restTime - _delay) / _duration;
    if (progress <= 0 || progress >= 1) return (offset: 0, angle: 0);

    // Two slow rocks under a bell-shaped envelope avoid a snap at either end
    final taper = math.sin(progress * math.pi);
    final gain = taper * taper * (1 - _settleTime / _settleDuration);
    final phase = progress * 4 * math.pi;
    return (
      offset: math.sin(phase) * 2.2 * gain,
      angle: math.sin(phase - math.pi / 6) * 0.045 * gain,
    );
  }
}
