import 'dart:math' as math;
import 'dart:ui' as ui;

/// Draws the bramble sprig with one visible blade per remaining edible leaf
///
/// Record the curves in local coordinates. A resize only changes the canvas
/// transform, and eating rerecords this sprig alone
class WoodlandSprigArt {
  ui.Picture? _picture;
  int? _paintedEatenLeaves;

  void draw(
    ui.Canvas canvas,
    ui.Tangent anchor,
    double scale,
    int eatenLeaves,
  ) {
    if (_picture == null || _paintedEatenLeaves != eatenLeaves) {
      final recorder = ui.PictureRecorder();
      _paintSprig(ui.Canvas(recorder), eatenLeaves);
      _picture?.dispose();
      _picture = recorder.endRecording();
      _paintedEatenLeaves = eatenLeaves;
    }
    canvas.save();
    canvas.translate(anchor.position.dx, anchor.position.dy);
    canvas.rotate(math.atan2(anchor.vector.dy, anchor.vector.dx));
    canvas.scale(scale);
    canvas.drawPicture(_picture!);
    canvas.restore();
  }

  void dispose() {
    _picture?.dispose();
    _picture = null;
  }
}

// Keep the stems as the blades disappear so the player can see where food was
void _paintSprig(ui.Canvas canvas, int eatenLeaves) {
  const blades = [
    (ui.Offset(10, -29), -0.18),
    (ui.Offset(5, -22), -2.55),
    (ui.Offset(5, -15), -0.40),
    (ui.Offset(2, -9), -2.85),
  ];
  final stemPaint = ui.Paint()
    ..color = const ui.Color.from(alpha: 1, red: 0.37, green: 0.44, blue: 0.25)
    ..style = ui.PaintingStyle.stroke
    ..strokeCap = ui.StrokeCap.round
    ..strokeWidth = 1.3;
  canvas.drawPath(
    ui.Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(2, -18, 10, -29),
    stemPaint,
  );
  for (var index = eatenLeaves; index < blades.length; index++) {
    final (base, angle) = blades[index];
    _paintLeaf(canvas, base, index == 0 ? 0.90 : 0.72, angle);
  }
}

void _paintLeaf(ui.Canvas canvas, ui.Offset base, double scale, double angle) {
  canvas.save();
  canvas.translate(base.dx, base.dy);
  canvas.rotate(angle);
  canvas.scale(scale);
  final blade = ui.Path()
    ..moveTo(0, 0)
    ..lineTo(5, -5)
    ..lineTo(8, -5)
    ..lineTo(11, -8)
    ..quadraticBezierTo(15, -7, 22, -8)
    ..lineTo(19, -3)
    ..lineTo(20, -1)
    ..lineTo(15, 2)
    ..lineTo(13, 5)
    ..quadraticBezierTo(8, 6, 0, 0)
    ..close();
  canvas.drawPath(
    blade,
    ui.Paint()
      ..shader = ui.Gradient.linear(
        const ui.Offset(0, -8),
        const ui.Offset(0, 5),
        const [
          ui.Color.from(alpha: 1, red: 0.65, green: 0.76, blue: 0.36),
          ui.Color.from(alpha: 1, red: 0.31, green: 0.48, blue: 0.27),
        ],
      ),
  );
  canvas.drawLine(
    const ui.Offset(0, 0),
    const ui.Offset(18, -5),
    ui.Paint()
      ..color = const ui.Color.from(
        alpha: 0.8,
        red: 0.23,
        green: 0.36,
        blue: 0.21,
      )
      ..strokeWidth = 0.8,
  );
  canvas.restore();
}
