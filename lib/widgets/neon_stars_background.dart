import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Rende uno sfondo di stelline neon con effetto pulsante a cascata.
/// Alcune stelle pulsano, altre restano costanti, creando un effetto
/// "twinkle" che si propaga in onde.
class NeonStarsBackground extends StatefulWidget {
  final int starCount;

  const NeonStarsBackground({
    super.key,
    this.starCount = 70,
  });

  @override
  State<NeonStarsBackground> createState() => _NeonStarsBackgroundState();
}

class _NeonStarsBackgroundState extends State<NeonStarsBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _TwinkleStarsPainter(
              time: _controller.value,
              starCount: widget.starCount,
            ),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class _TwinkleStarsPainter extends CustomPainter {
  final double time;
  final int starCount;

  const _TwinkleStarsPainter({
    required this.time,
    required this.starCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    final rng = math.Random(42);

    for (var i = 0; i < starCount; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final baseRadius = 0.8 + rng.nextDouble() * 1.8;
      final phase = rng.nextDouble() * 2 * math.pi;
      final speed = 1.0 + rng.nextDouble() * 3.0;
      final pinkAmount = rng.nextDouble();

      // Pulse value: oscillates between 0.0 and 1.0 (full dark to full bright)
      final pulse = 0.5 + 0.5 * math.sin(time * speed * math.pi + phase);

      // Opacity: da quasi spento (0.04) a brillante (0.55)
      final opacity = 0.04 + pulse * 0.45;

      // Colore base: mescola pink e cyan
      final color = Color.lerp(
        const Color(0xFF8EC5FF),
        const Color(0xFFFF5FA2),
        pinkAmount,
      )!;

      final starColor = color.withOpacity(opacity);

      // Outer glow (netto quando pulse > 0.3)
      if (pulse > 0.25) {
        final glowStrength = (pulse - 0.25) * 0.3;
        canvas.drawCircle(
          Offset(x, y),
          baseRadius * 6,
          Paint()
            ..shader = RadialGradient(
              colors: [
                color.withOpacity(glowStrength),
                color.withOpacity(0),
              ],
            ).createShader(
              Rect.fromCircle(center: Offset(x, y), radius: baseRadius * 6),
            ),
        );
      }

      // Core (sempre visibile, ma dimensioni variabili)
      final coreRadius = baseRadius * (0.6 + 0.4 * pulse);
      canvas.drawCircle(
        Offset(x, y),
        coreRadius,
        Paint()..color = color.withOpacity(opacity + 0.15),
      );

      // Spikes incrociate (solo quando pulse > 0.4)
      if (pulse > 0.4) {
        final spikeLen = baseRadius * (1.5 + 1.5 * pulse);
        final spikePaint = Paint()
          ..color = color.withOpacity(opacity * 0.35)
          ..strokeWidth = 0.5;
        canvas.drawLine(Offset(x - spikeLen, y), Offset(x + spikeLen, y), spikePaint);
        canvas.drawLine(Offset(x, y - spikeLen), Offset(x, y + spikeLen), spikePaint);
      }
    }
  }

  @override
  bool shouldRepaint(_TwinkleStarsPainter old) => old.time != time;
}
