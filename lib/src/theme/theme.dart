import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'tokens.dart';

/// Builds a complete Material 3 theme in the Basalt style, so plain Material widgets
/// (cards, inputs, dialogs, sheets, chips, list tiles, navigation) already look right.
ThemeData basaltTheme(Brightness brightness, BasaltAccent accent) {
  final p = BasaltPalette.build(brightness, accent);
  final scheme = ColorScheme(
    brightness: brightness,
    primary: p.accent,
    onPrimary: p.onAccent,
    primaryContainer: p.accentSoft,
    onPrimaryContainer: p.accent,
    secondary: p.accent,
    onSecondary: p.onAccent,
    secondaryContainer: p.fill,
    onSecondaryContainer: p.text,
    tertiary: p.warning,
    onTertiary: p.bg,
    error: p.danger,
    onError: Colors.white,
    errorContainer: p.dangerSoft,
    onErrorContainer: p.danger,
    surface: p.surface,
    onSurface: p.text,
    onSurfaceVariant: p.textMuted,
    surfaceContainerLowest: p.bg,
    surfaceContainerLow: p.surface,
    surfaceContainer: p.surface,
    surfaceContainerHigh: p.surfaceRaised,
    surfaceContainerHighest: p.fill,
    surfaceTint: Colors.transparent,
    outline: p.border,
    outlineVariant: p.border,
    shadow: Colors.black,
    scrim: p.overlay,
    inverseSurface: p.text,
    onInverseSurface: p.bg,
    inversePrimary: p.accent,
  );

  TextStyle c(TextStyle s, Color color) => s.copyWith(color: color, fontFamily: BasaltType.family, package: BasaltType.package);
  final textTheme = TextTheme(
    displayLarge: c(BasaltType.hero, p.text),
    displayMedium: c(BasaltType.hero, p.text),
    displaySmall: c(BasaltType.display, p.text),
    headlineLarge: c(BasaltType.display, p.text),
    headlineMedium: c(BasaltType.display, p.text),
    headlineSmall: c(BasaltType.title, p.text),
    titleLarge: c(BasaltType.title, p.text),
    titleMedium: c(BasaltType.heading, p.text),
    titleSmall: c(BasaltType.bodyStrong, p.text),
    bodyLarge: c(BasaltType.body, p.text),
    bodyMedium: c(BasaltType.body, p.text),
    bodySmall: c(BasaltType.caption, p.textMuted),
    labelLarge: c(BasaltType.bodyStrong, p.text),
    labelMedium: c(BasaltType.label, p.textMuted),
    labelSmall: c(BasaltType.overline, p.textFaint),
  );

  final rounded = RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.lg));
  final fieldBorder = OutlineInputBorder(
    borderRadius: BorderRadius.circular(Radii.md),
    borderSide: BorderSide(color: p.border),
  );
  const buttonPadding = EdgeInsets.symmetric(horizontal: Gap.lg, vertical: 13);
  final buttonShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.md));
  final buttonText = c(BasaltType.bodyStrong, p.text).copyWith(fontWeight: FontWeight.w600);
  // Calm press feedback: a faint overlay, no ripple splash.
  final overlay = WidgetStateProperty.resolveWith<Color?>(
    (s) => s.contains(WidgetState.pressed) ? p.text.withValues(alpha: 0.06) : null,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    fontFamily: BasaltType.family,
    package: BasaltType.package,
    textTheme: textTheme,
    scaffoldBackgroundColor: p.bg,
    canvasColor: p.bg,
    dividerColor: p.border,
    splashFactory: NoSplash.splashFactory,
    highlightColor: p.text.withValues(alpha: 0.05),
    extensions: [p],
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: p.bg,
      foregroundColor: p.text,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: c(BasaltType.heading, p.text).copyWith(fontSize: 17),
      systemOverlayStyle: p.isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
    ),
    cardTheme: CardThemeData(
      color: p.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Radii.lg),
        side: BorderSide(color: p.border),
      ),
    ),
    dividerTheme: DividerThemeData(color: p.border, thickness: 1, space: 1),
    listTileTheme: ListTileThemeData(
      iconColor: p.textMuted,
      textColor: p.text,
      titleTextStyle: c(BasaltType.bodyStrong, p.text),
      subtitleTextStyle: c(BasaltType.caption, p.textMuted),
      contentPadding: const EdgeInsets.symmetric(horizontal: Gap.lg),
      minVerticalPadding: Gap.md,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.md)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: p.fill,
      isDense: false,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      hintStyle: c(BasaltType.body, p.textFaint),
      labelStyle: c(BasaltType.body, p.textMuted),
      floatingLabelStyle: c(BasaltType.label, p.accent),
      helperStyle: c(BasaltType.caption, p.textMuted),
      errorStyle: c(BasaltType.caption, p.danger),
      prefixIconColor: p.textMuted,
      suffixIconColor: p.textMuted,
      border: fieldBorder,
      enabledBorder: fieldBorder.copyWith(borderSide: const BorderSide(color: Colors.transparent)),
      focusedBorder: fieldBorder.copyWith(borderSide: BorderSide(color: p.accent, width: 1.4)),
      errorBorder: fieldBorder.copyWith(borderSide: BorderSide(color: p.danger)),
      focusedErrorBorder: fieldBorder.copyWith(borderSide: BorderSide(color: p.danger, width: 1.4)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.disabled) ? p.fill : p.accent),
        foregroundColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.disabled) ? p.textFaint : p.onAccent),
        overlayColor: WidgetStatePropertyAll(p.onAccent.withValues(alpha: 0.08)),
        padding: const WidgetStatePropertyAll(buttonPadding),
        shape: WidgetStatePropertyAll(buttonShape),
        textStyle: WidgetStatePropertyAll(buttonText),
        elevation: const WidgetStatePropertyAll(0),
        minimumSize: const WidgetStatePropertyAll(Size(64, 46)),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStatePropertyAll(p.accent),
        foregroundColor: WidgetStatePropertyAll(p.onAccent),
        overlayColor: WidgetStatePropertyAll(p.onAccent.withValues(alpha: 0.08)),
        padding: const WidgetStatePropertyAll(buttonPadding),
        shape: WidgetStatePropertyAll(buttonShape),
        textStyle: WidgetStatePropertyAll(buttonText),
        elevation: const WidgetStatePropertyAll(0),
        minimumSize: const WidgetStatePropertyAll(Size(64, 46)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStatePropertyAll(p.text),
        backgroundColor: WidgetStatePropertyAll(p.surface),
        overlayColor: overlay,
        side: WidgetStatePropertyAll(BorderSide(color: p.border)),
        padding: const WidgetStatePropertyAll(buttonPadding),
        shape: WidgetStatePropertyAll(buttonShape),
        textStyle: WidgetStatePropertyAll(buttonText),
        minimumSize: const WidgetStatePropertyAll(Size(64, 46)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStatePropertyAll(p.accent),
        overlayColor: overlay,
        shape: WidgetStatePropertyAll(buttonShape),
        textStyle: WidgetStatePropertyAll(buttonText),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStatePropertyAll(p.text),
        overlayColor: overlay,
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: p.accent,
      foregroundColor: p.onAccent,
      elevation: 0,
      focusElevation: 0,
      hoverElevation: 0,
      highlightElevation: 0,
      extendedTextStyle: buttonText,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.xl)),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: p.surface,
      selectedColor: p.accentSoft,
      disabledColor: p.fill,
      side: BorderSide(color: p.border),
      labelStyle: c(BasaltType.label, p.text),
      secondaryLabelStyle: c(BasaltType.label, p.accent),
      checkmarkColor: p.accent,
      iconTheme: IconThemeData(color: p.textMuted, size: 16),
      padding: const EdgeInsets.symmetric(horizontal: Gap.sm, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.pill)),
      showCheckmark: false,
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? p.surfaceRaised : p.fill),
        foregroundColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? p.text : p.textMuted),
        side: WidgetStatePropertyAll(BorderSide(color: p.border)),
        textStyle: WidgetStatePropertyAll(c(BasaltType.label, p.text)),
        shape: WidgetStatePropertyAll(buttonShape),
      ),
      selectedIcon: const SizedBox.shrink(),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? p.onAccent : p.textMuted),
      trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? p.accent : p.fill),
      trackOutlineColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? p.accent : p.border),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? p.accent : Colors.transparent),
      checkColor: WidgetStatePropertyAll(p.onAccent),
      side: BorderSide(color: p.textFaint, width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? p.accent : p.textFaint),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: p.accent,
      inactiveTrackColor: p.fill,
      thumbColor: p.accent,
      overlayColor: p.accentSoft,
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: p.accent,
      linearTrackColor: p.fill,
      circularTrackColor: p.fill,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: p.surface,
      surfaceTintColor: Colors.transparent,
      indicatorColor: p.accentSoft,
      elevation: 0,
      height: 66,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      iconTheme: WidgetStateProperty.resolveWith(
        (s) => IconThemeData(color: s.contains(WidgetState.selected) ? p.accent : p.textMuted, size: 22),
      ),
      labelTextStyle: WidgetStateProperty.resolveWith(
        (s) => c(BasaltType.label, s.contains(WidgetState.selected) ? p.text : p.textMuted).copyWith(fontSize: 12),
      ),
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: p.text,
      unselectedLabelColor: p.textMuted,
      indicatorColor: p.accent,
      dividerColor: p.border,
      labelStyle: c(BasaltType.label, p.text).copyWith(fontWeight: FontWeight.w600),
      unselectedLabelStyle: c(BasaltType.label, p.textMuted),
      overlayColor: overlay,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: p.surfaceRaised,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.xl), side: BorderSide(color: p.border)),
      titleTextStyle: c(BasaltType.title, p.text),
      contentTextStyle: c(BasaltType.body, p.textMuted),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: p.surfaceRaised,
      surfaceTintColor: Colors.transparent,
      modalBackgroundColor: p.surfaceRaised,
      elevation: 0,
      showDragHandle: true,
      dragHandleColor: p.border,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: p.surfaceRaised,
      surfaceTintColor: Colors.transparent,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.md), side: BorderSide(color: p.border)),
      textStyle: c(BasaltType.body, p.text),
    ),
    menuTheme: MenuThemeData(
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(p.surfaceRaised),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        shape: WidgetStatePropertyAll(rounded),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: p.isDark ? const Color(0xFFECEDEF) : const Color(0xFF1B1E23),
      contentTextStyle: c(BasaltType.label, p.isDark ? const Color(0xFF111318) : const Color(0xFFECEDEF)),
      actionTextColor: p.isDark ? accent.light : accent.dark,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.md)),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(color: p.text, borderRadius: BorderRadius.circular(Radii.sm)),
      textStyle: c(BasaltType.caption, p.bg),
    ),
    datePickerTheme: DatePickerThemeData(
      backgroundColor: p.surfaceRaised,
      surfaceTintColor: Colors.transparent,
      headerBackgroundColor: p.surfaceRaised,
      headerForegroundColor: p.text,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.xl)),
    ),
    timePickerTheme: TimePickerThemeData(
      backgroundColor: p.surfaceRaised,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Radii.xl)),
    ),
    expansionTileTheme: ExpansionTileThemeData(
      iconColor: p.textMuted,
      collapsedIconColor: p.textMuted,
      shape: const Border(),
      collapsedShape: const Border(),
    ),
  );
}
