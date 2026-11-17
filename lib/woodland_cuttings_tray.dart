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
  bool _dragging = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (_dragging)
          for (final sprig in widget.sprigs)
            if (sprig.dropBounds case final bounds?)
              Positioned.fromRect(
                rect: bounds,
                child: DragTarget<_Cutting>(
                  onWillAcceptWithDetails: (_) => true,
                  // Accepting a drop is the only action that changes foliage.
                  // A canceled drag just hides the targets again
                  onAcceptWithDetails: (_) => sprig.feeding.replenish(),
                  builder: (context, candidates, _) => DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: candidates.isEmpty
                          ? Colors.transparent
                          : const Color.from(
                              alpha: 0.32,
                              red: 0.65,
                              green: 0.79,
                              blue: 0.49,
                            ),
                      border: Border.all(color: _CuttingChip.ink, width: 2),
                    ),
                  ),
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
              onDragEnd: (_) => setState(() => _dragging = false),
              // Lift the preview above the finger while hit testing at the finger
              feedback: const FractionalTranslation(
                translation: Offset(-0.5, -1),
                child: _CuttingChip(label: 'Bramble cutting'),
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
