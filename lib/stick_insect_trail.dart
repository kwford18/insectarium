import 'dart:math' as math;
import 'dart:ui' as ui;

import 'stick_insect_walk.dart';

/// Converts whole strides into distances along one woodland contour
///
/// Both contours can share a stopping point on the soil by leaving the same
/// margin at the ground end. Align the branch endpoint to that stride grid
/// so switching contours on the shared floor preserves the stance height
class StickInsectTrail {
  StickInsectTrail({
    required this.metric,
    required this.groundStart,
    required this.scale,
    double? sharedFloorMargin,
  }) {
    final margin = math.min(55 * scale, metric.length / 4);
    final stride = StickInsectWalk.strideLength * scale;
    if (sharedFloorMargin == null) {
      strides = ((metric.length - 2 * margin) / stride).floor();
      start = (metric.length - strides * stride) / 2;
      end = metric.length - start;
    } else {
      end = metric.length - sharedFloorMargin;
      strides = math.max(0, ((end - margin) / stride).floor());
      start = end - strides * stride;
    }
  }

  final ui.PathMetric metric;
  final double groundStart;
  final double scale;
  late final int strides;
  late final double start;
  late final double end;

  double get floorMargin => metric.length - end;

  /// Measures from the branch end on descent and from the floor on ascent
  double distanceAt(double strides, bool returning) {
    final distance = strides * StickInsectWalk.strideLength * scale;
    return returning ? end - distance : start + distance;
  }

  ui.Tangent tangentAt(double distance) =>
      metric.getTangentForOffset(distance.clamp(0.0, metric.length))!;
}
