import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'woodland_sprig.dart';

enum _Cutting { bramble }

/// Lets the player drag fresh bramble foliage onto a woodland sprig
///
/// This overlay fills the same viewport as the Flame scene. The scene supplies
/// the sprig bounds in viewport coordinates, and targets exist only while a
/// cutting is held so ordinary taps still reach the insect
class WoodlandCuttingsTray extends StatefulWidget {
  const WoodlandCuttingsTray({super.key, required this.sprigs});

  final List<WoodlandSprig> sprigs;

  @override
  State<WoodlandCuttingsTray> createState() => _WoodlandCuttingsTrayState();
}

class _WoodlandCuttingsTrayState extends State<WoodlandCuttingsTray> {
  final _feedbackKey = GlobalKey();
  bool _dragging = false;
  WoodlandSprig? _highlightedSprig;

  WoodlandSprig? _sprigAt(Offset globalPointer) {
    final preview = _feedbackKey.currentContext?.findRenderObject();
    if (preview is! RenderBox || !preview.hasSize) return null;
    final viewport = context.findRenderObject()! as RenderBox;
    final pointer = viewport.globalToLocal(globalPointer);
    final radius = preview.size.height / 2;
    final center = pointer - Offset(0, radius);
    final halfSegment = math.max(0.0, preview.size.width / 2 - radius);
    WoodlandSprig? closest;
    var closestDistance = double.infinity;
    for (final sprig in widget.sprigs) {
      final bounds = sprig.dropBounds;
      if (bounds == null) continue;
      // Treat the preview as its visible pill shape. A stem's circle overlaps
      // it when its center is within the combined radii of the pill's centerline
      final delta = bounds.center - center;
      final lineOffset = Offset(
        math.max(0.0, delta.dx.abs() - halfSegment),
        delta.dy,
      );
      final reach = radius + bounds.width / 2;
      if (lineOffset.distanceSquared <= reach * reach &&
          delta.distanceSquared < closestDistance) {
        closest = sprig;
        closestDistance = delta.distanceSquared;
      }
    }
    return closest;
  }

  void _highlight(WoodlandSprig? sprig) {
    if (_highlightedSprig != sprig) setState(() => _highlightedSprig = sprig);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (_dragging)
          DragTarget<_Cutting>(
            hitTestBehavior: HitTestBehavior.opaque,
            onWillAcceptWithDetails: (_) => true,
            onMove: (details) => _highlight(_sprigAt(details.offset)),
            onLeave: (_) => _highlight(null),
            // Flutter routes actual drops through the scene target. Use the
            // preview overlap to pick the sprig, including on the final event
            onAcceptWithDetails: (details) =>
                _sprigAt(details.offset)?.feeding.replenish(),
            builder: (context, candidates, rejected) => Stack(
              children: [
                for (final sprig in widget.sprigs)
                  if (sprig.dropBounds case final bounds?)
                    Positioned.fromRect(
                      rect: bounds,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: sprig == _highlightedSprig
                              ? const Color.from(
                                  alpha: 0.32,
                                  red: 0.65,
                                  green: 0.79,
                                  blue: 0.49,
                                )
                              : Colors.transparent,
                          border: Border.all(color: _CuttingChip.ink, width: 2),
                        ),
                      ),
                    ),
              ],
            ),
          ),
        SafeArea(
          minimum: const EdgeInsets.only(bottom: 16),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Draggable<_Cutting>(
              data: _Cutting.bramble,
              maxSimultaneousDrags: 1,
              dragAnchorStrategy: pointerDragAnchorStrategy,
              onDragStarted: () => setState(() => _dragging = true),
              onDragEnd: (_) => setState(() {
                _dragging = false;
                _highlightedSprig = null;
              }),
              // Keep this translation in sync with the overlap calculation
              feedback: FractionalTranslation(
                key: _feedbackKey,
                translation: const Offset(-0.5, -1),
                child: const _CuttingChip(label: 'Bramble cutting'),
              ),
              childWhenDragging: const _CuttingChip(label: 'Drop on a stem'),
              child: const _CuttingChip(label: 'Drag bramble cutting'),
            ),
          ),
        ),
      ],
    );
  }
}

class _CuttingChip extends StatelessWidget {
  const _CuttingChip({required this.label});

  static const ink = Color.from(alpha: 1, red: 0.19, green: 0.28, blue: 0.20);
  static const _paper = Color.from(
    alpha: 1,
    red: 0.94,
    green: 0.90,
    blue: 0.80,
  );

  final String label;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _paper,
      shape: const StadiumBorder(side: BorderSide(color: ink)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.eco_outlined, size: 20, color: ink),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: ink)),
          ],
        ),
      ),
    );
  }
}
