import 'package:flutter/material.dart';

/// Lightweight, code-drawn football artwork that keeps the app visually rich
/// without adding a large image download to the booking journey.
class SportsIllustration extends StatelessWidget {
  const SportsIllustration({
    super.key,
    this.height = 180,
    this.compact = false,
    this.label = 'رسم توضيحي لملعب كرة قدم',
  });

  final double height;
  final bool compact;
  final String label;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Semantics(
      label: label,
      image: true,
      child: ExcludeSemantics(
        child: SizedBox(
          height: height,
          width: double.infinity,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(compact ? 22 : 30),
            child: CustomPaint(
              painter: _PitchPainter(
                primary: colors.primary,
                secondary: colors.secondary,
                isDark: Theme.of(context).brightness == Brightness.dark,
              ),
              child: Stack(
                children: [
                  PositionedDirectional(
                    top: compact ? 16 : 22,
                    end: compact ? 16 : 22,
                    child: _GlowDot(color: colors.secondary, size: 10),
                  ),
                  PositionedDirectional(
                    top: compact ? 42 : 56,
                    start: compact ? 20 : 32,
                    child: _GlowDot(color: colors.onPrimary, size: 6),
                  ),
                  Align(
                    alignment: Alignment.center,
                    child: Container(
                      width: compact ? 54 : 76,
                      height: compact ? 54 : 76,
                      decoration: BoxDecoration(
                        color: colors.onPrimary.withValues(alpha: 0.13),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: colors.onPrimary.withValues(alpha: 0.24),
                        ),
                      ),
                      child: Icon(
                        Icons.sports_soccer,
                        color: colors.onPrimary,
                        size: compact ? 31 : 42,
                      ),
                    ),
                  ),
                  PositionedDirectional(
                    bottom: compact ? 14 : 20,
                    start: compact ? 16 : 26,
                    child: Text(
                      compact ? 'READY' : 'PLAY YOUR GAME',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colors.onPrimary.withValues(alpha: 0.76),
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.6,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlowDot extends StatelessWidget {
  const _GlowDot({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: color,
      shape: BoxShape.circle,
      boxShadow: [BoxShadow(color: color, blurRadius: 16, spreadRadius: 2)],
    ),
  );
}

class _PitchPainter extends CustomPainter {
  const _PitchPainter({
    required this.primary,
    required this.secondary,
    required this.isDark,
  });

  final Color primary;
  final Color secondary;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect area = Offset.zero & size;
    final Paint background = Paint()
      ..shader = LinearGradient(
        colors: [
          primary.withValues(alpha: isDark ? 0.86 : 0.98),
          Color.lerp(primary, const Color(0xFF062E22), 0.74)!,
        ],
        // Canvas painters do not inherit a TextDirection in widget tests.
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(area);
    canvas.drawRect(area, background);

    final Paint stripePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.045);
    final double stripeWidth = size.width / 7;
    for (int index = 0; index < 7; index += 2) {
      canvas.drawRect(
        Rect.fromLTWH(index * stripeWidth, 0, stripeWidth, size.height),
        stripePaint,
      );
    }

    final Paint lines = Paint()
      ..color = Colors.white.withValues(alpha: 0.22)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.25;
    final RRect pitch = RRect.fromRectAndRadius(
      Rect.fromLTWH(18, 14, size.width - 36, size.height - 28),
      const Radius.circular(18),
    );
    canvas.drawRRect(pitch, lines);
    canvas.drawLine(
      Offset(size.width / 2, 14),
      Offset(size.width / 2, size.height - 14),
      lines,
    );
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.shortestSide * 0.18,
      lines,
    );
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      2.6,
      Paint()..color = Colors.white.withValues(alpha: 0.36),
    );

    final double boxWidth = size.width * 0.19;
    final double boxHeight = size.height * 0.46;
    canvas.drawRect(
      Rect.fromLTWH(18, (size.height - boxHeight) / 2, boxWidth, boxHeight),
      lines,
    );
    canvas.drawRect(
      Rect.fromLTWH(
        size.width - 18 - boxWidth,
        (size.height - boxHeight) / 2,
        boxWidth,
        boxHeight,
      ),
      lines,
    );

    final Paint accent = Paint()..color = secondary.withValues(alpha: 0.85);
    canvas.drawCircle(Offset(size.width * 0.17, size.height * 0.18), 3, accent);
    canvas.drawCircle(Offset(size.width * 0.78, size.height * 0.74), 4, accent);
  }

  @override
  bool shouldRepaint(covariant _PitchPainter oldDelegate) =>
      oldDelegate.primary != primary ||
      oldDelegate.secondary != secondary ||
      oldDelegate.isDark != isDark;
}
