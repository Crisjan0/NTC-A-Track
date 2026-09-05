import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../utils/app_theme.dart';
import '../utils/constants.dart';

/// The colorful "wallpaper" every liquid-glass screen sits on top of.
///
/// Paints a soft base gradient plus large, heavily blurred color blobs, so the
/// frosted [GlassPanel]s above it read as translucent glass. Colors adapt to
/// the current brightness. Optionally paints slowly drifting blobs when
/// [animated] is true.
class LiquidBackground extends StatefulWidget {
  const LiquidBackground({super.key, this.child, this.animated = false});

  /// Optional content painted on top of the wallpaper (the app UI).
  final Widget? child;

  /// When true the blobs gently drift (reduced motion friendly).
  final bool animated;

  @override
  State<LiquidBackground> createState() => _LiquidBackgroundState();
}

class _LiquidBackgroundState extends State<LiquidBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 40),
  );

  @override
  void initState() {
    super.initState();
    if (widget.animated) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = AppTheme.paletteOf(context);
    final t = widget.animated ? _controller.value * 2 * math.pi : 0.0;

    return ColoredBox(
      color: p.wallpaperTop,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Base gradient.
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [p.wallpaperTop, p.wallpaperBottom],
              ),
            ),
          ),
          // Soft color blobs.
          LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final h = constraints.maxHeight;
              final blobs = widget.animated
                  ? _animatedBlobs(p, w, h, t)
                  : _staticBlobs(p, w, h);
              return ClipRect(
                child: Stack(
                  fit: StackFit.expand,
                  children: blobs,
                ),
              );
            },
          ),
          // Gentle grain-free top-light veil keeps glass readable.
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    p.isDark
                        ? Colors.black.withValues(alpha: 0.18)
                        : Colors.white.withValues(alpha: 0.35),
                    Colors.transparent,
                    p.isDark
                        ? Colors.black.withValues(alpha: 0.25)
                        : Colors.white.withValues(alpha: 0.0),
                  ],
                  stops: const [0.0, 0.35, 1.0],
                ),
              ),
            ),
          ),
          if (widget.child != null) widget.child!,
        ],
      ),
    );
  }

  List<Widget> _staticBlobs(GlassPalette p, double w, double h) {
    final spots = <({Alignment a, double size, int color})>[
      (a: const Alignment(-1.15, -1.25), size: 1.5, color: 0),
      (a: const Alignment(1.2, -0.9), size: 1.15, color: 1),
      (a: const Alignment(1.25, 1.1), size: 1.3, color: 2),
      (a: const Alignment(-1.2, 1.2), size: 1.25, color: 3),
      (a: const Alignment(0.05, -0.15), size: 0.95, color: 4),
    ];
    return spots.map((s) => _blob(p, w, h, s.a, s.size, s.color)).toList();
  }

  List<Widget> _animatedBlobs(GlassPalette p, double w, double h, double t) {
    final spots = <({Alignment a, double size, int color})>[
      (a: const Alignment(-1.1, -1.2), size: 1.5, color: 0),
      (a: const Alignment(1.2, -0.85), size: 1.15, color: 1),
      (a: const Alignment(1.25, 1.15), size: 1.3, color: 2),
      (a: const Alignment(-1.25, 1.2), size: 1.25, color: 3),
      (a: const Alignment(0.0, -0.1), size: 0.9, color: 4),
    ];
    // Slight circular drift around each resting position.
    return List.generate(spots.length, (i) {
      final s = spots[i];
      final phase = t + i * (2 * math.pi / spots.length);
      final dx = math.sin(phase) * 0.08;
      final dy = math.cos(phase * 0.9) * 0.06;
      final a = Alignment(
        s.a.x + dx,
        s.a.y + dy,
      );
      return _blob(p, w, h, a, s.size, s.color);
    });
  }

  Widget _blob(
    GlassPalette p,
    double w,
    double h,
    Alignment alignment,
    double size,
    int colorIndex,
  ) {
    final c = p.blobColors[colorIndex % p.blobColors.length];
    final diameter = w * size;
    return Align(
      alignment: alignment,
      child: Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 0.55,
            colors: [
              c.withValues(alpha: p.blobOpacity),
              c.withValues(alpha: p.blobOpacity * 0.35),
              c.withValues(alpha: 0),
            ],
            stops: const [0.0, 0.55, 1.0],
          ),
        ),
      ),
    );
  }
}
