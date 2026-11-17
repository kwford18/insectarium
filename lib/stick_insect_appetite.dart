/// Tracks hunger and the current meal for the woodland stick insect
///
/// Hunger advances with the simulation clock. A meal can start only when the
/// caller reports an edible leaf in reach. Route choice stays with the insect
class StickInsectAppetite {
  static const _mealSeconds = 1.5;
  static const _betweenMeals = 12.0;

  // Let a fresh specimen get hungry during its first branch rest
  double _untilHungry = 4;
  double _mealProgress = 0;

  /// Returns whether to hold the insect at the sprig and whether a meal finished
  ({bool feeding, bool finished}) advance(
    double seconds, {
    required bool leafInReach,
  }) {
    if (_untilHungry > 0) {
      _untilHungry -= seconds;
      // Use only the part of this tick after hunger begins as eating time
      seconds = -_untilHungry;
    }
    if (!leafInReach || seconds <= 0) {
      return (feeding: false, finished: false);
    }

    _mealProgress += seconds;
    if (_mealProgress < _mealSeconds) {
      return (feeding: true, finished: false);
    }

    _mealProgress = 0;
    _untilHungry = _betweenMeals;
    return (feeding: true, finished: true);
  }
}
