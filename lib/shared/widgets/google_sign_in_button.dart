import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A familiar OAuth entry that keeps Google's visual identity distinct from
/// the app's primary booking action.
class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Semantics(
      label: label,
      button: true,
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: OutlinedButton.icon(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            foregroundColor: colors.onSurface,
            backgroundColor: colors.surface,
            side: BorderSide(color: colors.outlineVariant),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          icon: isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colors.primary,
                  ),
                )
              : const _GoogleMark(),
          label: Text(isLoading ? 'ثانية واحدة...' : label),
        ),
      ),
    );
  }
}

class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: SizedBox(
      width: 21,
      height: 21,
      child: CustomPaint(painter: _GoogleMarkPainter()),
    ),
  );
}

class _GoogleMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Rect ring = Rect.fromLTWH(2, 2, size.width - 4, size.height - 4);
    const double strokeWidth = 3.4;

    void arc(Color color, double start, double sweep) {
      canvas.drawArc(
        ring,
        start * math.pi / 180,
        sweep * math.pi / 180,
        false,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.butt,
      );
    }

    arc(const Color(0xffea4335), 205, 95);
    arc(const Color(0xfffbbc05), 135, 75);
    arc(const Color(0xff34a853), 45, 95);
    arc(const Color(0xff4285f4), -45, 90);

    final Paint blue = Paint()
      ..color = const Color(0xff4285f4)
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;
    canvas.drawLine(
      Offset(size.width / 2, size.height / 2),
      Offset(size.width - 1.4, size.height / 2),
      blue,
    );
  }

  @override
  bool shouldRepaint(covariant _GoogleMarkPainter oldDelegate) => false;
}
