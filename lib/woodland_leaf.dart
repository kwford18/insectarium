import 'dart:ui' as ui;

/// Paints the offered bramble leaf with its near tip at the insect's mouth
///
/// The center vein and uneven outline distinguish the serving from the
/// enclosure's decorative foliage
void paintWoodlandLeaf(
  ui.Canvas canvas,
  ui.Offset tip,
  double scale,
  double angle,
) {
  canvas.save();
  canvas.translate(tip.dx, tip.dy);
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
