import 'package:flutter/material.dart';

class FieldNote extends StatelessWidget {
  const FieldNote({super.key, required this.onClose});

  final VoidCallback onClose;

  static const _paper = Color(0xFFFBF0D7);
  static const _ink = Color(0xFF324437);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 16, end: 0),
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          builder: (context, offset, child) =>
              Transform.translate(offset: Offset(0, offset), child: child),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 380),
            child: Material(
              color: _paper,
              elevation: 6,
              shadowColor: const Color(0x443C3020),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(18)),
                side: BorderSide(color: Color(0xFFCCBA93)),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 12, 22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Field note',
                            style: TextStyle(
                              color: _ink,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: onClose,
                          style: TextButton.styleFrom(foregroundColor: _ink),
                          child: const Text('Close note'),
                        ),
                      ],
                    ),
                    Semantics(
                      header: true,
                      child: const Text(
                        'Stick insect',
                        style: TextStyle(
                          color: _ink,
                          fontFamily: 'YoungSerif',
                          fontSize: 28,
                          height: 1.15,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: Text(
                        'Watch how some feet grip the branch while the others '
                        'reach forward.',
                        style: TextStyle(
                          color: _ink,
                          fontSize: 16,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
