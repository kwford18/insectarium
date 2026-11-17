import 'package:flutter/foundation.dart';

/// Manages the single bramble leaf offered at the prototype's branch station
///
/// Availability drives the offer button and the visible leaf. The insect
/// advances the meal only while resting within reach of the branch station
class WoodlandFeeding extends ChangeNotifier {
  static const foodId = 'bramble-leaf';
  static const foodName = 'Bramble leaf';
  static const _mealSeconds = 1.5;

  bool _hasLeaf = false;
  double _eatingSeconds = 0;

  bool get hasLeaf => _hasLeaf;

  /// Offers a portion only when the previous one has been consumed
  void offerLeaf() {
    if (_hasLeaf) return;
    _hasLeaf = true;
    notifyListeners();
  }

  /// Consumes the leaf after a full meal and reports completion exactly once
  bool advanceMeal(double seconds) {
    if (!_hasLeaf) return false;

    _eatingSeconds += seconds;
    if (_eatingSeconds < _mealSeconds) return false;
    _hasLeaf = false;
    _eatingSeconds = 0;
    notifyListeners();
    return true;
  }
}
