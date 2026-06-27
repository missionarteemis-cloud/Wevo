// wevo_buttons.dart
// Sistema bottoni per Wevo — gradiente brand + varianti sobrie.
//
// Palette gradiente:  #FA61A6  →  #A4A8F3  →  #6DD7D7
//
// WevoColors e brand gradient -> theme.dart

import 'dart:math' as math;
import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import '../theme.dart';

enum WevoSize { s, m, l }

/// ---------------------------------------------------------------------------
/// Bottone primario — gradiente brand con glow.
/// ---------------------------------------------------------------------------
class WevoGradientButton extends StatefulWidget {
  const WevoGradientButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.size = WevoSize.m,
    this.fullWidth = false,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final WevoSize size;
  final bool fullWidth;
  final bool loading;

  @override
  State<WevoGradientButton> createState() => _WevoGradientButtonState();
}

class _WevoGradientButtonState extends State<WevoGradientButton> {
  bool _down = false;

  EdgeInsets get _pad => switch (widget.size) {
        WevoSize.s => const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        WevoSize.m => const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
        WevoSize.l => const EdgeInsets.symmetric(horizontal: 38, vertical: 18),
      };

  double get _font => switch (widget.size) {
        WevoSize.s => 14,
        WevoSize.m => 16,
        WevoSize.l => 19,
      };

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onPressed == null || widget.loading;
    final radius = widget.fullWidth ? 22.0 : 999.0;

    Widget child;
    if (widget.loading) {
      child = const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2.6,
          valueColor: AlwaysStoppedAnimation(Colors.white),
        ),
      );
    } else {
      child = Row(
        mainAxisSize: widget.fullWidth ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            widget.label,
            style: TextStyle(
              color: Colors.white,
              fontSize: _font,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.2,
            ),
          ),
          if (widget.icon != null) ...[
            const SizedBox(width: 10),
            Icon(widget.icon, color: Colors.white, size: _font + 4),
          ],
        ],
      );
    }

    return Opacity(
      opacity: disabled && widget.onPressed == null ? 0.4 : 1,
      child: GestureDetector(
        onTapDown: disabled ? null : (_) => setState(() => _down = true),
        onTapUp: disabled ? null : (_) => setState(() => _down = false),
        onTapCancel: disabled ? null : () => setState(() => _down = false),
        onTap: disabled ? null : widget.onPressed,
        child: AnimatedScale(
          scale: _down ? 0.985 : 1,
          duration: const Duration(milliseconds: 120),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            width: widget.fullWidth ? double.infinity : null,
            padding: widget.fullWidth
                ? const EdgeInsets.symmetric(vertical: 18)
                : _pad,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: WevoColors.brand,
              borderRadius: BorderRadius.circular(radius),
              boxShadow: disabled
                  ? null
                  : [
                      BoxShadow(
                        color: WevoColors.pink.withOpacity(_down ? 0.24 : 0.34),
                        blurRadius: _down ? 18 : 30,
                        offset: const Offset(0, 12),
                      ),
                    ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Varianti sobrie, senza gradiente.
enum WevoVariant { solid, neutral, outline, ghost }

/// ---------------------------------------------------------------------------
/// Bottone sobrio — tinta piena / superficie scura / bordo / testo.
/// ---------------------------------------------------------------------------
class WevoButton extends StatefulWidget {
  const WevoButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.variant = WevoVariant.neutral,
    this.color = WevoColors.pink,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final WevoVariant variant;

  /// Colore d'accento per solid / outline / ghost.
  final Color color;

  @override
  State<WevoButton> createState() => _WevoButtonState();
}

class _WevoButtonState extends State<WevoButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.color;
    late Color bg, fg, border;
    final hov = _hover;

    switch (widget.variant) {
      case WevoVariant.solid:
        bg = hov ? Color.lerp(c, Colors.black, 0.1)! : c;
        fg = c == WevoColors.teal ? WevoColors.ink : Colors.white;
        border = Colors.transparent;
        break;
      case WevoVariant.neutral:
        bg = hov ? WevoColors.surfaceHi : WevoColors.surface;
        fg = WevoColors.textHi;
        border = Colors.white.withOpacity(0.1);
        break;
      case WevoVariant.outline:
        bg = hov ? c.withOpacity(0.08) : Colors.transparent;
        fg = c;
        border = c.withOpacity(hov ? 1 : 0.5);
        break;
      case WevoVariant.ghost:
        bg = hov ? Colors.white.withOpacity(0.05) : Colors.transparent;
        fg = c == WevoColors.pink ? WevoColors.textHi : c;
        border = Colors.transparent;
        break;
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border, width: 1.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, color: fg, size: 17),
                const SizedBox(width: 9),
              ],
              Text(
                widget.label,
                style: TextStyle(
                  color: fg,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// Bottone circolare con icona — swipe / azioni rapide.
/// ---------------------------------------------------------------------------
class WevoIconButton extends StatefulWidget {
  const WevoIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.size = 64,
    this.gradient = false,
    this.accent = WevoColors.pink,
    this.filled = false,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final double size;

  /// true → riempi col gradiente brand (es. il like principale).
  final bool gradient;

  /// Colore per il bordo/icona nelle varianti outline.
  final Color accent;

  /// true → superficie scura piena (variante neutral).
  final bool filled;

  @override
  State<WevoIconButton> createState() => _WevoIconButtonState();
}

class _WevoIconButtonState extends State<WevoIconButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final hov = _hover;
    final Color iconColor =
        widget.gradient ? Colors.white : (widget.filled ? WevoColors.textHi : widget.accent);

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedScale(
          scale: hov ? 1.1 : 1,
          duration: const Duration(milliseconds: 150),
          child: Container(
            width: widget.size,
            height: widget.size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: widget.gradient ? WevoColors.brand : null,
              color: widget.gradient
                  ? null
                  : (widget.filled
                      ? WevoColors.surface
                      : widget.accent.withOpacity(0.08)),
              border: widget.gradient
                  ? null
                  : Border.all(
                      color: widget.filled
                          ? Colors.white.withOpacity(0.1)
                          : widget.accent.withOpacity(0.5),
                      width: widget.filled ? 1 : 2,
                    ),
              boxShadow: (widget.gradient && hov) ||
                      (!widget.gradient && hov && !widget.filled)
                  ? [
                      BoxShadow(
                        color: (widget.gradient ? WevoColors.pink : widget.accent)
                            .withOpacity(0.5),
                        blurRadius: 24,
                      ),
                    ]
                  : null,
            ),
            child: Icon(widget.icon, color: iconColor, size: widget.size * 0.46),
          ),
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// Bottone neon — solo contorno gradiente, riempimento scuro, glow.
/// Usa un GradientBoxBorder dipinto a mano (niente pacchetti esterni).
/// ---------------------------------------------------------------------------
class WevoNeonButton extends StatefulWidget {
  const WevoNeonButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.size = WevoSize.m,
    this.gradientText = false,
    this.fullWidth = false,
    this.borderRadius = 999,
    this.fill = WevoColors.ink,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final WevoSize size;

  /// true → testo col gradiente brand invece che bianco.
  final bool gradientText;
  final bool fullWidth;
  final double borderRadius;

  /// Colore di riempimento interno (scuro).
  final Color fill;

  @override
  State<WevoNeonButton> createState() => _WevoNeonButtonState();
}

class _WevoNeonButtonState extends State<WevoNeonButton> {
  bool _hover = false;

  EdgeInsets get _pad => switch (widget.size) {
        WevoSize.s => const EdgeInsets.symmetric(horizontal: 19, vertical: 9),
        WevoSize.m => const EdgeInsets.symmetric(horizontal: 26, vertical: 13),
        WevoSize.l => const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
      };

  double get _font => switch (widget.size) {
        WevoSize.s => 14,
        WevoSize.m => 16,
        WevoSize.l => 19,
      };

  @override
  Widget build(BuildContext context) {
    final r = Radius.circular(widget.borderRadius);

    Widget label = Text(
      widget.label,
      style: TextStyle(
        color: Colors.white,
        fontSize: _font,
        fontWeight: FontWeight.w700,
      ),
    );
    if (widget.gradientText) {
      label = ShaderMask(
        shaderCallback: (b) => WevoColors.brand.createShader(b),
        child: label, // il colore base viene sostituito dallo shader
      );
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: widget.fullWidth ? double.infinity : null,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.all(r),
            boxShadow: [
              BoxShadow(
                color: (_hover ? WevoColors.pink : WevoColors.periwinkle)
                    .withOpacity(_hover ? 0.5 : 0.3),
                blurRadius: _hover ? 30 : 18,
              ),
            ],
          ),
          child: CustomPaint(
            painter: _GradientBorderPainter(
              radius: widget.borderRadius,
              width: widget.size == WevoSize.l ? 2.5 : 2,
              fill: widget.fill,
            ),
            child: Padding(
              padding: _pad,
              child: Row(
                mainAxisSize: widget.fullWidth ? MainAxisSize.max : MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.icon != null) ...[
                    Icon(widget.icon, color: WevoColors.periwinkle, size: _font + 2),
                    const SizedBox(width: 9),
                  ],
                  label,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Dipinge il riempimento scuro + un bordo col gradiente brand.
class _GradientBorderPainter extends CustomPainter {
  _GradientBorderPainter({
    required this.radius,
    required this.width,
    required this.fill,
  });

  final double radius;
  final double width;
  final Color fill;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rr = RRect.fromRectAndRadius(rect, Radius.circular(radius));

    // riempimento
    canvas.drawRRect(rr, Paint()..color = fill);

    // bordo gradiente
    final inset = rect.deflate(width / 2);
    final rrBorder =
        RRect.fromRectAndRadius(inset, Radius.circular(radius - width / 2));
    final border = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = width
      ..shader = WevoColors.brand.createShader(rect);
    canvas.drawRRect(rrBorder, border);
  }

  @override
  bool shouldRepaint(_GradientBorderPainter old) =>
      old.radius != radius || old.width != width || old.fill != fill;
}

/// ---------------------------------------------------------------------------
/// Chip vibe a stato (off / on col gradiente).
/// ---------------------------------------------------------------------------
class WevoVibeChip extends StatelessWidget {
  const WevoVibeChip({
    super.key,
    required this.label,
    required this.icon,
    this.selected = false,
    this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Colors.white : WevoColors.textHi;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
        decoration: BoxDecoration(
          gradient: selected ? WevoColors.brand : null,
          color: selected ? null : Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? Colors.transparent : Colors.white.withOpacity(0.14),
            width: 1.5,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: WevoColors.periwinkle.withOpacity(0.32),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: fg, size: 16),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    color: fg, fontSize: 14, fontWeight: FontWeight.w700)),
            if (selected) ...[
              const SizedBox(width: 8),
              const Icon(Icons.check, color: Colors.white, size: 15),
            ],
          ],
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// Segmented control — opzione attiva col gradiente brand.
/// ---------------------------------------------------------------------------
class WevoSegmented extends StatelessWidget {
  const WevoSegmented({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  final List<String> options;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: const Color(0xFF15101F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(options.length, (i) {
          final active = i == value;
          return GestureDetector(
            onTap: () => onChanged(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
              decoration: BoxDecoration(
                gradient: active ? WevoColors.brand : null,
                borderRadius: BorderRadius.circular(12),
                boxShadow: active
                    ? [
                        BoxShadow(
                            color: WevoColors.pink.withOpacity(.32),
                            blurRadius: 16,
                            offset: const Offset(0, 6))
                      ]
                    : null,
              ),
              child: Text(
                options[i],
                style: TextStyle(
                  color: active ? Colors.white : WevoColors.textMid,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// Room button — "Entra nella room" (online, bordo verde a gradiente +
/// pallino neon pulsante) / "Bussa alla porta" (offline, bordo spento +
/// pallino grigio).
/// ---------------------------------------------------------------------------
class WevoRoomButton extends StatefulWidget {
  const WevoRoomButton({
    super.key,
    this.online = true,
    this.onlineLabel = 'Entra nella room',
    this.offlineLabel = 'Bussa alla porta',
    this.onTap,
  });

  final bool online;
  final String onlineLabel;
  final String offlineLabel;
  final VoidCallback? onTap;

  @override
  State<WevoRoomButton> createState() => _WevoRoomButtonState();
}

class _WevoRoomButtonState extends State<WevoRoomButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _dot = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1800));

  @override
  void initState() {
    super.initState();
    if (widget.online) _dot.repeat();
  }

  @override
  void didUpdateWidget(WevoRoomButton old) {
    super.didUpdateWidget(old);
    if (widget.online && !_dot.isAnimating) {
      _dot.repeat();
    } else if (!widget.online && _dot.isAnimating) {
      _dot.stop();
    }
  }

  @override
  void dispose() {
    _dot.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final online = widget.online;
    return GestureDetector(
      onTap: widget.onTap,
      child: CustomPaint(
        painter: online ? _GreenBorderPainter() : null,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          decoration: BoxDecoration(
            color: online ? const Color(0xFF0D1418) : const Color(0xFF120B20),
            borderRadius: BorderRadius.circular(18),
            border: online
                ? null
                : Border.all(color: const Color(0x4D9694A8), width: 1.5),
            boxShadow: online
                ? [
                    BoxShadow(
                        color: const Color(0xFF4DF0A0).withOpacity(.22),
                        blurRadius: 18)
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedBuilder(
                animation: _dot,
                builder: (_, __) {
                  final pulse = online ? math.sin(_dot.value * math.pi) : 0.0;
                  final c = online
                      ? const Color(0xFF4DF0A0)
                      : const Color(0xFF7C778F);
                  return Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: c,
                      boxShadow: [
                        BoxShadow(
                          color: c.withOpacity(online ? 0.9 : 0.5),
                          blurRadius: online ? 10 + 4 * pulse : 6,
                          spreadRadius: online ? 1.0 * pulse : 0,
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(width: 11),
              Text(
                online ? widget.onlineLabel : widget.offlineLabel,
                style: TextStyle(
                  color: online
                      ? const Color(0xFFCFF7E6)
                      : const Color(0xFF9A95AD),
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GreenBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rr =
        RRect.fromRectAndRadius(rect.deflate(1), const Radius.circular(18));
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..shader = const LinearGradient(
        colors: [Color(0xFF6DD7D7), Color(0xFF5BE6A8), Color(0xFF3FD98A)],
        stops: [0.0, 0.55, 1.0],
      ).createShader(rect);
    canvas.drawRRect(rr, paint);
  }

  @override
  bool shouldRepaint(_GreenBorderPainter old) => false;
}

/// ---------------------------------------------------------------------------
/// Finestra d'errore sobria (niente gradiente).
/// ---------------------------------------------------------------------------
class WevoErrorDialog extends StatelessWidget {
  const WevoErrorDialog({
    super.key,
    this.title = 'Qualcosa è andato storto',
    this.message =
        'Non siamo riusciti a caricare i nuovi profili. Controlla la connessione e riprova.',
    this.code = 'ERR_NETWORK · 503',
    this.cancelLabel = 'Annulla',
    this.confirmLabel = 'Riprova',
    this.onCancel,
    this.onConfirm,
  });

  final String title;
  final String message;
  final String? code;
  final String cancelLabel;
  final String confirmLabel;
  final VoidCallback? onCancel;
  final VoidCallback? onConfirm;

  /// Helper: mostra il dialog con la barriera scura di Wevo.
  static Future<T?> show<T>(BuildContext context,
          {WevoErrorDialog? dialog}) =>
      showDialog<T>(
        context: context,
        barrierColor: Colors.black.withOpacity(.55),
        builder: (_) => dialog ?? const WevoErrorDialog(),
      );

  @override
  Widget build(BuildContext context) {
    const coral = Color(0xFFFF8F8F);
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(28),
      child: Container(
        width: 420,
        decoration: BoxDecoration(
          color: const Color(0xFF161020),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(.55),
                blurRadius: 70,
                offset: const Offset(0, 30))
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(30, 32, 30, 26),
              child: Column(
                children: [
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: coral.withOpacity(.1),
                      border: Border.all(color: coral.withOpacity(.28)),
                    ),
                    child: const Icon(Icons.warning_amber_rounded,
                        color: coral, size: 32),
                  ),
                  const SizedBox(height: 20),
                  Text(title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontFamily: 'Fredoka',
                          fontSize: 23,
                          fontWeight: FontWeight.w600,
                          color: Colors.white)),
                  const SizedBox(height: 12),
                  Text(message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 15,
                          height: 1.6,
                          color: WevoColors.textMid)),
                  if (code != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withOpacity(0.07)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.wifi_off_rounded,
                              color: coral, size: 15),
                          const SizedBox(width: 8),
                          Text(code!,
                              style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                  color: Color(0xFF8B85A0))),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(26, 0, 26, 26),
              child: Row(
                children: [
                  Expanded(
                    child: WevoButton(
                      label: cancelLabel,
                      variant: WevoVariant.outline,
                      color: const Color(0xFFE4E0EF),
                      onPressed:
                          onCancel ?? () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: WevoButton(
                      label: confirmLabel,
                      variant: WevoVariant.solid,
                      color: WevoColors.pink,
                      onPressed: onConfirm,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Banner d'errore / warning inline.
enum WevoBannerKind { error, warning }

class WevoBanner extends StatelessWidget {
  const WevoBanner({
    super.key,
    required this.title,
    required this.message,
    this.kind = WevoBannerKind.error,
    this.onTap,
  });

  final String title;
  final String message;
  final WevoBannerKind kind;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final accent = kind == WevoBannerKind.error
        ? const Color(0xFFFF8F8F)
        : const Color(0xFFFFC76A);
    final titleColor = kind == WevoBannerKind.error
        ? const Color(0xFFFFB3B3)
        : const Color(0xFFFFD99A);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: accent.withOpacity(0.06),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: accent.withOpacity(0.22)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.warning_amber_rounded, color: accent, size: 20),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          color: titleColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 14)),
                  const SizedBox(height: 3),
                  Text(message,
                      style: const TextStyle(
                          color: WevoColors.textMid, fontSize: 13)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// Glass card (glassmorphism) — colori brand portati verso il dark.
/// ---------------------------------------------------------------------------
enum WevoTint { pink, periwinkle, teal }

class WevoGlassCard extends StatelessWidget {
  const WevoGlassCard({
    super.key,
    required this.child,
    this.tint = WevoTint.pink,
    this.padding = const EdgeInsets.all(22),
    this.radius = 22,
  });

  final Widget child;
  final WevoTint tint;
  final EdgeInsets padding;
  final double radius;

  // tinte profonde (versione scura del colore brand) + accento per il glow
  ({Color a, Color b, Color border, Color accent}) get _palette {
    switch (tint) {
      case WevoTint.pink:
        return (
          a: const Color(0x8C7A2A52),
          b: const Color(0x731C1026),
          border: const Color(0x2EFF8FB0),
          accent: WevoColors.pink
        );
      case WevoTint.periwinkle:
        return (
          a: const Color(0x8C34386C),
          b: const Color(0x7318122A),
          border: const Color(0x2EA4A8F3),
          accent: WevoColors.periwinkle
        );
      case WevoTint.teal:
        return (
          a: const Color(0x8C1E4A4A),
          b: const Color(0x73141C26),
          border: const Color(0x2E6DD7D7),
          accent: WevoColors.teal
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _palette;
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [p.a, p.b],
            ),
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: p.border),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(.4),
                  blurRadius: 44,
                  offset: const Offset(0, 18))
            ],
          ),
          child: Stack(
            children: [
              // highlight morbido in alto a sinistra
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(-0.6, -1),
                      radius: 1.0,
                      colors: [
                        p.accent.withOpacity(.16),
                        Colors.transparent
                      ],
                      stops: const [0.0, 0.6],
                    ),
                  ),
                ),
              ),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

/// Card statistica pronta all'uso, costruita su WevoGlassCard.
class WevoStatCard extends StatelessWidget {
  const WevoStatCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.trend,
    this.tint = WevoTint.pink,
  });

  final IconData icon;
  final String value;
  final String label;
  final String trend;
  final WevoTint tint;

  Color get _accent => switch (tint) {
        WevoTint.pink => const Color(0xFFFF9CC2),
        WevoTint.periwinkle => const Color(0xFFBFC2FF),
        WevoTint.teal => const Color(0xFF8FE8E8),
      };

  @override
  Widget build(BuildContext context) {
    return WevoGlassCard(
      tint: tint,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _accent.withOpacity(.14),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: _accent.withOpacity(.25)),
            ),
            child: Icon(icon, color: _accent, size: 22),
          ),
          const SizedBox(height: 18),
          Text(value,
              style: const TextStyle(
                  fontFamily: 'Fredoka',
                  fontSize: 34,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  height: 1)),
          const SizedBox(height: 4),
          Text(label,
              style:
                  const TextStyle(fontSize: 13, color: Color(0xFFC9C3DE))),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.trending_up, color: _accent, size: 13),
                const SizedBox(width: 5),
                Text(trend,
                    style: TextStyle(
                        color: _accent,
                        fontWeight: FontWeight.w700,
                        fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ---------------------------------------------------------------------------
/// Esempio d'uso.
/// ---------------------------------------------------------------------------
void _noop(int _) {}

class WevoButtonsDemo extends StatelessWidget {
  const WevoButtonsDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: WevoColors.ink,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: [
              WevoGradientButton(
                label: 'Trova vibe',
                icon: Icons.arrow_forward_rounded,
                size: WevoSize.l,
                onPressed: () {},
              ),
              WevoButton(
                label: 'Dettagli',
                variant: WevoVariant.outline,
                color: WevoColors.periwinkle,
                onPressed: () {},
              ),
              WevoButton(
                label: 'Annulla',
                variant: WevoVariant.ghost,
                onPressed: () {},
              ),
              WevoIconButton(
                icon: Icons.favorite,
                gradient: true,
                size: 74,
                onPressed: () {},
              ),
              WevoIconButton(
                icon: Icons.close,
                accent: const Color(0xFFFF7D7D),
                onPressed: () {},
              ),
              const WevoVibeChip(
                label: 'Gaming',
                icon: Icons.sports_esports,
                selected: true,
              ),
              WevoNeonButton(
                label: 'Premium',
                gradientText: true,
                onPressed: () {},
              ),
              WevoNeonButton(
                label: 'Boost',
                icon: Icons.bolt,
                onPressed: () {},
              ),
              const WevoSegmented(
                options: ['Vibe', 'Distanza', 'Online'],
                value: 0,
                onChanged: _noop,
              ),
              const WevoRoomButton(online: true),
              const WevoRoomButton(online: false),
              Builder(
                builder: (context) => WevoButton(
                  label: 'Mostra errore',
                  variant: WevoVariant.neutral,
                  onPressed: () => WevoErrorDialog.show(context),
                ),
              ),
              const SizedBox(
                width: 240,
                child: WevoBanner(
                  title: 'Messaggio non inviato',
                  message: 'Tocca per riprovare l\'invio.',
                ),
              ),
              const SizedBox(
                width: 220,
                child: WevoStatCard(
                  icon: Icons.favorite,
                  value: '128',
                  label: 'Match totali',
                  trend: '+12 questa settimana',
                  tint: WevoTint.pink,
                ),
              ),
              const SizedBox(
                width: 220,
                child: WevoStatCard(
                  icon: Icons.group_outlined,
                  value: '46',
                  label: 'Vibe avviate',
                  trend: '5 attive ora',
                  tint: WevoTint.periwinkle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}