import 'package:flutter/material.dart';

import 'glass_panel.dart';
import 'liquid_background.dart';

/// A full-screen liquid-glass page: a colorful [LiquidBackground] wallpaper
/// with a transparent [Scaffold] floating above it. Use this for any route
/// pushed on top of the shell so the wallpaper is continuous.
class GlassScaffold extends StatelessWidget {
  const GlassScaffold({
    super.key,
    this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.resizeToAvoidBottomInset = true,
    this.extendBody = false,
    this.extendBodyBehindAppBar = false,
    this.animated = false,
    this.safeAreaBody = false,
  });

  final Widget? body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final bool resizeToAvoidBottomInset;
  final bool extendBody;
  final bool extendBodyBehindAppBar;

  /// Gently drifts the wallpaper blobs.
  final bool animated;

  /// Wraps [body] in a [SafeArea] before placing it.
  final bool safeAreaBody;

  @override
  Widget build(BuildContext context) {
    final content = SafeArea(child: body ?? const SizedBox.shrink());

    return LiquidBackground(
      animated: animated,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        resizeToAvoidBottomInset: resizeToAvoidBottomInset,
        extendBody: extendBody,
        extendBodyBehindAppBar: extendBodyBehindAppBar,
        appBar: appBar,
        body: safeAreaBody ? content : body ?? const SizedBox.shrink(),
        bottomNavigationBar: bottomNavigationBar,
        floatingActionButton: floatingActionButton,
        floatingActionButtonLocation: floatingActionButtonLocation,
      ),
    );
  }
}

/// A frosted glass pill used as the app bar of pushed pages: back button,
/// title and actions sit in a translucent, blurred capsule over the wallpaper.
class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  const GlassAppBar({
    super.key,
    this.title,
    this.actions,
    this.leading,
    this.automaticallyImplyLeading = true,
    this.height = 60,
  });

  final Widget? title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool automaticallyImplyLeading;
  final double height;

  @override
  Size get preferredSize => Size.fromHeight(height + 12);

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: GlassPanel(
        radius: 22,
        blur: 34,
        strong: true,
        borderWidth: 1,
        showSheen: true,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: SizedBox(
          height: height - 20,
          child: Row(
            children: [
              if (leading != null)
                leading!
              else if (automaticallyImplyLeading && canPop)
                IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.4),
                  ),
                ),
              if (title != null) ...[
                const SizedBox(width: 6),
                Expanded(
                  child: DefaultTextStyle(
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    child: title!,
                  ),
                ),
              ] else
                const Spacer(),
              ...?actions,
            ],
          ),
        ),
      ),
    );
  }
}
