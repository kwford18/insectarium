import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';

import 'woodland_feeding.dart';
import 'woodland_leaf.dart';

/// A drawable sprig and its planting location in the enclosure
///
/// The route places the sprig at a reachable stop on resize. Drawing and touch
/// targeting use that same anchor so they remain aligned at different sizes
class WoodlandSprig extends Component {
  WoodlandSprig({this.uphill = false});

  final bool uphill;
  final feeding = WoodlandFeeding();
  final _art = WoodlandSprigArt();
  ui.Tangent? _anchor;
  double _scale = 1;

  /// Positions the sprig, or hides it if the current route has no suitable stop
  void place(ui.Tangent? anchor, double scale) {
    _anchor = anchor;
    _scale = scale;
  }

  /// The touch area covers the stem and keeps at least a 48-unit target
  ui.Rect? get dropBounds {
    final anchor = _anchor;
    if (anchor == null) return null;
    final along = anchor.vector * ((uphill ? -5 : 5) * _scale);
    final up = ui.Offset(anchor.vector.dy, -anchor.vector.dx) * (15 * _scale);
    return ui.Rect.fromCircle(
      center: anchor.position + along + up,
      radius: math.max(24, 24 * _scale),
    );
  }

  @override
  void render(ui.Canvas canvas) {
    final anchor = _anchor;
    if (anchor != null) {
      _art.draw(canvas, anchor, _scale, feeding.eatenLeaves, uphill: uphill);
    }
  }

  @override
  void onRemove() {
    _art.dispose();
    super.onRemove();
  }
}
