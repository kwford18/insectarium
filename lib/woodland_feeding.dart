/// The edible leaves on one woodland sprig
///
/// The prototype eats them in a fixed order, so the count identifies which
/// individual leaves are still attached. A fresh cutting restores the sprig
class WoodlandFeeding {
  static const foodId = 'bramble-leaf';
  static const foodName = 'Bramble leaf';
  static const leafCount = 4;

  int _eatenLeaves = 0;

  int get eatenLeaves => _eatenLeaves;
  bool get hasLeaf => _eatenLeaves < leafCount;

  /// Removes one leaf if any remain and reports whether it was eaten
  bool eatLeaf() {
    if (!hasLeaf) return false;
    _eatenLeaves++;
    return true;
  }

  /// Replaces the leaves on this sprig with a fresh cutting
  void replenish() {
    _eatenLeaves = 0;
  }
}
