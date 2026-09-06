import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'constants.dart';

/// Central theme for the liquid-glass UI. Light and dark appearances both
/// use the same visual language: frosted translucent panels floating over a
/// colorful blurred wallpaper (see LiquidBackground / GlassPanel).
class AppTheme {
  AppTheme._();

  /// FIXED PALETTE - Always uses the same minimalist grayscale colors
  static GlassPalette paletteOf(BuildContext context) => GlassPalette.fixed;

  /// FIXED THEME - Always uses minimalist grayscale (never changes)
  static ThemeData get light => _build(GlassPalette.fixed);

  /// FIXED THEME - Always uses minimalist grayscale (never changes)
  static ThemeData get dark => _build(GlassPalette.fixed);

  static ThemeData _build(GlassPalette p) {
    // FIXED MINIMALIST COLORS - Never changes based on system theme
    final primary = AppColors.primary;  // Fixed gray
    final onPrimary = Colors.white;  // Fixed white text
    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,  // Fixed to light
      primary: primary,
      onPrimary: onPrimary,
      primaryContainer: BrandNavy.c100,
      onPrimaryContainer: BrandNavy.c900,
      secondary: AppColors.orange,  // Fixed gray
      onSecondary: Colors.white,  // Fixed white
      secondaryContainer: BrandNavy.c200,
      onSecondaryContainer: BrandNavy.c900,
      surface: Colors.white,  // Fixed white
      error: AppColors.danger,
      onSurface: Color(0xFF1A1A1A),  // Fixed dark text
      onSurfaceVariant: Color(0xFF666666),  // Fixed medium gray
      outline: Color(0xFFCCCCCC),  // Fixed light gray
      scrim: Color(0x33000000),  // Fixed scrim
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,  // Fixed to light
      colorScheme: scheme,
      scaffoldBackgroundColor: Colors.white,  // Fixed white background
    );

    // FIXED TEXT COLORS
    const Color textPrimary = Color(0xFF1A1A1A);  // Fixed dark gray
    const Color textSecondary = Color(0xFF666666);  // Fixed medium gray

    return base.copyWith(
      textTheme: base.textTheme.copyWith(
        displaySmall: base.textTheme.displaySmall?.copyWith(
          fontWeight: FontWeight.w800,
          color: textPrimary,
          letterSpacing: -0.5,
        ),
        headlineMedium: base.textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w800,
          color: textPrimary,
          letterSpacing: -0.5,
        ),
        headlineSmall: base.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        titleLarge: base.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
        titleMedium: base.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleSmall: base.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: textSecondary,
        ),
        bodyLarge: base.textTheme.bodyLarge?.copyWith(color: textPrimary),
        bodyMedium:
            base.textTheme.bodyMedium?.copyWith(color: textPrimary, height: 1.4),
        bodySmall: base.textTheme.bodySmall?.copyWith(color: textSecondary),
        labelLarge: base.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.2,
        ),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: Colors.white,  // Fixed white
        foregroundColor: textPrimary,
        systemOverlayStyle: SystemUiOverlayStyle.dark,  // Fixed dark icons
        titleTextStyle: base.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w800,
          color: textPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Color(0xFFF5F5F5),  // Fixed light gray
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(kCardRadius),
          side: BorderSide(color: Color(0xFFCCCCCC), width: 1),  // Fixed border
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Color(0xFFFAFAFA),  // Fixed very light gray
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: TextStyle(color: textSecondary),
        prefixIconColor: textSecondary,
        suffixIconColor: textSecondary,
        labelStyle: TextStyle(color: textSecondary, fontWeight: FontWeight.w600),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(kFieldRadius),
          borderSide: BorderSide(color: Color(0xFFCCCCCC), width: 1.2),  // Fixed
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(kFieldRadius),
          borderSide: BorderSide(color: Color(0xFFCCCCCC), width: 1.2),  // Fixed
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(kFieldRadius),
          borderSide: BorderSide(color: AppColors.primary, width: 1.8),  // Fixed primary
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(kFieldRadius),
          borderSide: const BorderSide(color: AppColors.danger),  // Fixed danger
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(kFieldRadius),
          borderSide: const BorderSide(color: AppColors.danger, width: 1.8),  // Fixed
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: Color(0xFF666666),  // Fixed dark gray button
          foregroundColor: Colors.white,  // Fixed white text
          minimumSize: const Size.fromHeight(36),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(kButtonRadius),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          backgroundColor: Color(0xFF666666),  // Fixed dark gray button
          foregroundColor: Colors.white,  // Fixed white text
          minimumSize: const Size.fromHeight(36),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(kButtonRadius),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(36),
          foregroundColor: Color(0xFF666666),  // Fixed dark gray text
          side: BorderSide(color: Color(0xFFCCCCCC)),  // Fixed border
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(kButtonRadius),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: Color(0xFF666666),  // Fixed dark gray text
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: Color(0xFFEEEEEE),  // Fixed light gray
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        side: BorderSide(color: Color(0xFFCCCCCC)),  // Fixed border
        labelStyle: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        secondaryLabelStyle: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFF666666),  // Fixed dark gray
        ),
        selectedColor: Color(0xFFDDDDDD),  // Fixed selected gray
        checkmarkColor: Color(0xFF333333),  // Fixed dark checkmark
      ),
      navigationBarTheme: NavigationBarThemeData(
        elevation: 0,
        height: 72,
        backgroundColor: Color(0xFFFAFAFA),  // Fixed very light gray
        indicatorColor: Color(0xFFEEEEEE),  // Fixed light gray
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        labelTextStyle: WidgetStatePropertyAll(
          TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: textSecondary,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? Color(0xFF666666)  // Fixed selected gray
                : textSecondary,
            size: 24,
          ),
        ),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        surfaceTintColor: Colors.transparent,
      ),
      dividerTheme: DividerThemeData(
        color: Color(0xFFCCCCCC),  // Fixed light gray
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Color(0xFF333333),  // Fixed dark gray
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Color(0xFFFAFAFA),  // Fixed very light gray
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(26),
          side: BorderSide(color: Color(0xFFCCCCCC)),  // Fixed border
        ),
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: textPrimary,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: Color(0xFFFAFAFA),  // Fixed very light gray
        modalBackgroundColor: Color(0xFFFAFAFA),  // Fixed
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        showDragHandle: true,
        dragHandleColor: textSecondary,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: Color(0xFF666666),  // Fixed dark gray
        linearTrackColor: Color(0xFFE0E0E0),  // Fixed light gray
        circularTrackColor: Color(0xFFE0E0E0),  // Fixed light gray
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.white
              : textSecondary,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.switchGreen
              : Colors.white.withValues(alpha: 0.6),  // Fixed
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.switchGreen
              : Colors.black.withValues(alpha: 0.15),  // Fixed
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: p.glassFillStrong,
        headerBackgroundColor: scheme.primary,
        headerForegroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(26),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: textSecondary,
        textColor: textPrimary,
        titleTextStyle: base.textTheme.bodyLarge?.copyWith(
          color: textPrimary,
          fontWeight: FontWeight.w600,
        ),
        subtitleTextStyle: base.textTheme.bodySmall?.copyWith(
          color: textSecondary,
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: scheme.primary,
        unselectedLabelColor: textSecondary,
        indicatorColor: scheme.primary,
        dividerColor: Colors.transparent,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        unselectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: p.glassFillStrong,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
