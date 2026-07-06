import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Exact brand tokens for the NALUM redesign. Centralised here so screens can
/// match the Stitch design pixel-for-pixel without re-deriving hex values.
///
/// These mirror the design system authored in Stitch (seed `#0F766E`,
/// Space Grotesk + Outfit, 1px `outlineVariant` card borders, 14px fields).
class AppColors {
  AppColors._();

  /// Primary teal — mentorship = trust (blue) + growth (green).
  static const Color primary = Color(0xFF0F766E);

  /// A slightly deeper teal used for the desktop brand-panel gradient end.
  static const Color primaryDeep = Color(0xFF0D615B);

  /// Brighter teal for accents on dark surfaces.
  static const Color primaryBright = Color(0xFF2DD4BF);

  /// Warm off-white scaffold background.
  static const Color surface = Color(0xFFFAFAF7);

  /// Raised card surface (light).
  static const Color card = Color(0xFFFFFFFF);

  /// Hairline border used on cards and app-bar dividers.
  static const Color outlineVariant = Color(0xFFE6E4DF);

  /// Secondary text / icon colour.
  static const Color onSurfaceVariant = Color(0xFF5C5C5C);

  /// Dark teal used for hero headlines on light surfaces.
  static const Color headline = Color(0xFF134E4A);

  /// Near-black text on light surfaces.
  static const Color onSurface = Color(0xFF0F0F12);

  // Status tints — desaturated, used only as small pills/tints.
  static const Color statusGreenBg = Color(0xFFDCFCE7);
  static const Color statusGreenText = Color(0xFF16A34A);
  static const Color statusAmberBg = Color(0xFFFEF3C7);
  static const Color statusAmberText = Color(0xFFD97706);
  static const Color statusRedBg = Color(0xFFFEE2E2);
  static const Color statusRedText = Color(0xFFDC2626);
  static const Color statusBlueBg = Color(0xFFDBEAFE);
  static const Color statusBlueText = Color(0xFF01579B);
  static const Color statusLavenderBg = Color(0xFFF3E8FF);
  static const Color statusLavenderText = Color(0xFF7E22CE);

  // Role-badge tints.
  static const Color alumniBg = Color(0xFFCCFBF1);
  static const Color alumniFg = Color(0xFF0F766E);
  static const Color studentBg = Color(0xFFDBEAFE);
  static const Color studentFg = Color(0xFF01579B);
  static const Color adminBg = Color(0xFFFEE2E2);
  static const Color adminFg = Color(0xFFB71C1C);

  // Dark-mode surfaces (real dark, not tinted light).
  static const Color darkSurface = Color(0xFF0F0F12);
  static const Color darkCard = Color(0xFF17171C);
  static const Color darkCardHigh = Color(0xFF1F1F25);
  static const Color darkOutlineVariant = Color(0xFF2A2A30);
  static const Color darkOnSurface = Color(0xFFEDEDF0);
  static const Color darkOnSurfaceVariant = Color(0xFFA1A1AA);

  /// Soft primary-tinted glow used on filled buttons, per the design system
  /// (`0 4px 14px 0 rgba(15, 118, 110, 0.25)`).
  static List<BoxShadow> primaryGlow({Color? color}) => <BoxShadow>[
    BoxShadow(
      color: (color ?? primary).withValues(alpha: 0.25),
      blurRadius: 14,
      offset: const Offset(0, 4),
    ),
  ];

  /// Very soft card lift used on desktop stat tiles.
  static List<BoxShadow> cardGlow() => <BoxShadow>[
    BoxShadow(
      color: primary.withValues(alpha: 0.08),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];
}

/// Centralized Material 3 themes for the Alumni Mentorship Platform.
///
/// Uses the NALUM teal (`#0F766E`) as the seed colour, pairs Space Grotesk
/// (display / headlines) with Outfit (body), and replaces heavy drop shadows
/// with 1px `outlineVariant` card borders for the Linear/Notion-inspired
/// surface language. Dark mode is a real dark theme on a near-black surface.
class AppTheme {
  AppTheme._();

  /// Light theme derived from the NALUM teal seed.
  static final ThemeData lightTheme = _build(brightness: Brightness.light);

  /// Dark theme — near-black surfaces, teal accents.
  static final ThemeData darkTheme = _build(brightness: Brightness.dark);

  static ThemeData _build({required Brightness brightness}) {
    final bool isDark = brightness == Brightness.dark;
    final ColorScheme base = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: brightness,
    );
    final ColorScheme colorScheme = isDark
        ? base.copyWith(
            surface: AppColors.darkSurface,
            onSurface: AppColors.darkOnSurface,
            surfaceContainerLowest: AppColors.darkSurface,
            surfaceContainerLow: AppColors.darkSurface,
            surfaceContainer: AppColors.darkCard,
            surfaceContainerHigh: AppColors.darkCard,
            surfaceContainerHighest: AppColors.darkCardHigh,
            onSurfaceVariant: AppColors.darkOnSurfaceVariant,
            outlineVariant: AppColors.darkOutlineVariant,
            primary: AppColors.primary,
            onPrimary: Colors.white,
          )
        : base.copyWith(
            surface: AppColors.surface,
            onSurface: AppColors.onSurface,
            surfaceContainerHighest: AppColors.outlineVariant,
            onSurfaceVariant: AppColors.onSurfaceVariant,
            outlineVariant: AppColors.outlineVariant,
            primary: AppColors.primary,
            onPrimary: Colors.white,
          );

    final TextTheme baseText = isDark
        ? ThemeData.dark().textTheme
        : ThemeData.light().textTheme;
    final TextTheme outfit = GoogleFonts.outfitTextTheme(baseText).apply(
      bodyColor: colorScheme.onSurface,
      displayColor: colorScheme.onSurface,
    );
    final TextTheme textTheme = outfit.copyWith(
      displayLarge: GoogleFonts.spaceGrotesk(
        textStyle: outfit.displayLarge,
        fontWeight: FontWeight.w600,
      ),
      displayMedium: GoogleFonts.spaceGrotesk(
        textStyle: outfit.displayMedium,
        fontWeight: FontWeight.w600,
      ),
      displaySmall: GoogleFonts.spaceGrotesk(
        textStyle: outfit.displaySmall,
        fontWeight: FontWeight.w600,
      ),
      headlineLarge: GoogleFonts.spaceGrotesk(
        textStyle: outfit.headlineLarge,
        fontWeight: FontWeight.w600,
      ),
      headlineMedium: GoogleFonts.spaceGrotesk(
        textStyle: outfit.headlineMedium,
        fontWeight: FontWeight.w600,
      ),
      headlineSmall: GoogleFonts.spaceGrotesk(
        textStyle: outfit.headlineSmall,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: GoogleFonts.spaceGrotesk(
        textStyle: outfit.titleLarge,
        fontWeight: FontWeight.w600,
      ),
    );

    final Color cardColor = isDark ? AppColors.darkCard : AppColors.card;
    final Color border = isDark
        ? AppColors.darkOutlineVariant
        : AppColors.outlineVariant;
    final Color inputFill =
        (isDark ? AppColors.darkCardHigh : AppColors.outlineVariant).withValues(
          alpha: 0.4,
        );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.spaceGrotesk(
          textStyle: textTheme.titleLarge,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        color: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: border, width: 1),
        ),
        surfaceTintColor: Colors.transparent,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          elevation: 2,
          shadowColor: colorScheme.primary.withValues(alpha: 0.25),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          elevation: 2,
          shadowColor: colorScheme.primary.withValues(alpha: 0.25),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.error, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: colorScheme.error, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
          color: colorScheme.onSurfaceVariant,
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStatePropertyAll<RoundedRectangleBorder>(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          backgroundColor: WidgetStateProperty.resolveWith<Color?>((
            Set<WidgetState> states,
          ) {
            if (states.contains(WidgetState.selected)) {
              return colorScheme.primary;
            }
            return Colors.transparent;
          }),
          foregroundColor: WidgetStateProperty.resolveWith<Color?>((
            Set<WidgetState> states,
          ) {
            if (states.contains(WidgetState.selected)) {
              return colorScheme.onPrimary;
            }
            return colorScheme.onSurfaceVariant;
          }),
          textStyle: WidgetStatePropertyAll<TextStyle?>(
            textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: cardColor,
        indicatorColor: colorScheme.primary.withValues(alpha: 0.12),
        labelTextStyle: WidgetStatePropertyAll<TextStyle?>(
          textTheme.labelMedium,
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: cardColor,
        indicatorColor: colorScheme.primary.withValues(alpha: 0.12),
        selectedLabelTextStyle: textTheme.labelMedium?.copyWith(
          color: colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelTextStyle: textTheme.labelMedium,
      ),
      dividerTheme: DividerThemeData(color: border, thickness: 1, space: 1),
    );
  }
}
