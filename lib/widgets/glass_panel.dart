import 'dart:ui';

import 'package:flutter/material.dart';

import '../utils/app_theme.dart';
import '../utils/constants.dart';

/// A frosted "liquid glass" surface.
///
/// Frosts everything behind it with a [BackdropFilter], tints it with the
/// theme's translucent glass fill, and finishes the edge with a bright
/// refractive hairline (stronger at the top-left, like iOS Liquid Glass).
///
/// ```
/// GlassPanel(
///   child: ...,
/// )
/// ```
class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.radius = kCardRadius,
    this.blur = 28,
    this.padding,
    this.fill,
    this.strong = false,
    this.showSheen = true,
    this.borderWidth = 1,
    this.shadow,
    this.clipBehavior = Clip.antiAlias,
    this.onTap,
    this.color,
  });

  /// Content placed on the frosted surface.
  final Widget child;

  /// Corner radius of the panel (outer).
  final double radius;

  /// Frost strength (Gaussian sigma in px). Larger = more frosted.
  final double blur;

  /// Padding around [child]. When null the panel adds no padding.
  final EdgeInsetsGeometry? padding;

  /// Explicit glass fill. Defaults to the theme glass fill.
  final Color? fill;

  /// Use the stronger (more opaque) fill variant.
  final bool strong;

  /// Paint a soft specular highlight across the top of the glass.
  final bool showSheen;

  /// Hairline stroke width around the glass.
  final double borderWidth;

  /// Optional drop shadow; null gives the default soft glass shadow.
  final BoxShadow? shadow;

  final Clip clipBehavior;

  /// When set, the whole panel is tappable.
  final VoidCallback? onTap;

  /// Optional tint layered over the glass (e.g. status colors).
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final p = AppTheme.paletteOf(context);
    final tint = color;
    final effectiveFill = tint != null
        ? tint.withValues(alpha: p.isDark ? 0.42 : 0.6)
        : (fill ?? (strong ? p.glassFillStrong : p.glassFill));
    final baseShadow = shadow ??
        BoxShadow(
          color: p.isDark
              ? Colors.black.withValues(alpha: 0.45)
              : AppColors.textPrimary.withValues(alpha: 0.08),
          blurRadius: 24,
          offset: const Offset(0, 10),
        );

    final Widget surface = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius - borderWidth),
        color: effectiveFill,
      ),
      child: padding == null ? child : Padding(padding: padding!, child: child),
    );

    final Widget blurred = ClipRRect(
      borderRadius: BorderRadius.circular(radius - borderWidth),
      clipBehavior: clipBehavior,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: surface,
      ),
    );

    // Refractive edge: a gradient "frame" drawn under the frosted body.
    final Widget framed = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            p.hairline,
            p.hairline.withValues(alpha: 0.35),
            p.borderStroke.withValues(alpha: 0.5),
            p.borderStroke,
          ],
          stops: const [0.0, 0.35, 0.8, 1.0],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(borderWidth),
        child: blurred,
      ),
    );

    Widget panel = framed;

    if (showSheen) {
      panel = Stack(
        clipBehavior: Clip.none,
        children: [
          panel,
          // Specular light streak across the top third of the glass.
          Positioned.fill(
            child: IgnorePointer(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(radius),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        p.hairline.withValues(alpha: p.isDark ? 0.12 : 0.5),
                        p.hairline.withValues(alpha: p.isDark ? 0.05 : 0.18),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.25, 1.0],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    final Widget content = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [baseShadow],
      ),
      child: panel,
    );

    if (onTap == null) return content;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        splashColor: p.textPrimary.withValues(alpha: 0.06),
        highlightColor: Colors.transparent,
        child: content,
      ),
    );
  }
}

/// A round glass avatar/tile — the liquid-glass version of an icon chip.
class GlassIconTile extends StatelessWidget {
  const GlassIconTile({
    super.key,
    required this.icon,
    this.size = 46,
    this.radius = 15,
    this.iconSize,
    this.color,
    this.iconColor,
  });

  final IconData icon;
  final double size;
  final double radius;
  final double? iconSize;
  final Color? color;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final p = AppTheme.paletteOf(context);
    return GlassPanel(
      radius: radius,
      blur: 12,
      borderWidth: 0.8,
      showSheen: false,
      padding: EdgeInsets.zero,
      color: color,
      child: SizedBox(
        width: size,
        height: size,
        child: Center(
          child: Icon(
            icon,
            size: iconSize ?? size * 0.46,
            color: iconColor ?? p.textPrimary,
          ),
        ),
      ),
    );
  }
}
