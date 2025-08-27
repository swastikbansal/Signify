// ignore_for_file: overridden_fields, annotate_overrides

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

const kThemeModeKey = '__theme_mode__';
SharedPreferences? _prefs;

enum DeviceSize { mobile, tablet, desktop }

abstract class FlutterFlowTheme {
  static DeviceSize deviceSize = DeviceSize.mobile;

  static Future initialize() async =>
      _prefs = await SharedPreferences.getInstance();

  static ThemeMode get themeMode {
    final darkMode = _prefs?.getBool(kThemeModeKey);
    return darkMode == null
        ? ThemeMode.system
        : darkMode
        ? ThemeMode.dark
        : ThemeMode.light;
  }

  static void saveThemeMode(ThemeMode mode) => mode == ThemeMode.system
      ? _prefs?.remove(kThemeModeKey)
      : _prefs?.setBool(kThemeModeKey, mode == ThemeMode.dark);

  static FlutterFlowTheme of(BuildContext context) {
    deviceSize = getDeviceSize(context);
    return Theme.of(context).brightness == Brightness.dark
        ? DarkModeTheme()
        : LightModeTheme();
  }

  @Deprecated('Use primary instead')
  Color get primaryColor => primary;

  @Deprecated('Use secondary instead')
  Color get secondaryColor => secondary;

  @Deprecated('Use tertiary instead')
  Color get tertiaryColor => tertiary;

  late Color primary;
  late Color secondary;
  late Color tertiary;
  late Color alternate;
  late Color primaryText;
  late Color secondaryText;
  late Color primaryBackground;
  late Color secondaryBackground;
  late Color accent1;
  late Color accent2;
  late Color accent3;
  late Color accent4;
  late Color success;
  late Color warning;
  late Color error;
  late Color info;

  late Color customColor1;
  late Color customColor2;
  late Color customColor3;
  late Color customColor4;
  late Color customColor5;
  late Color customColor6;
  late Color accentDict1;
  late Color accentDict2;
  late Color accentDict3;
  late Color accentDict4;
  late Color accentDict5;
  late Color accentDict6;
  late Color accentDict7;
  late Color accentDict8;
  late Color buttonShadow;
  late Color buttonShadow2;
  late Color gradient1;
  late Color gradient2;
  late Color accentDict11;
  late Color accentDict22;
  late Color accentDict33;
  late Color accentDict44;

  @Deprecated('Use displaySmallFamily instead')
  String get title1Family => displaySmallFamily;

  @Deprecated('Use displaySmall instead')
  TextStyle get title1 => typography.displaySmall;

  @Deprecated('Use headlineMediumFamily instead')
  String get title2Family => typography.headlineMediumFamily;

  @Deprecated('Use headlineMedium instead')
  TextStyle get title2 => typography.headlineMedium;

  @Deprecated('Use headlineSmallFamily instead')
  String get title3Family => typography.headlineSmallFamily;

  @Deprecated('Use headlineSmall instead')
  TextStyle get title3 => typography.headlineSmall;

  @Deprecated('Use titleMediumFamily instead')
  String get subtitle1Family => typography.titleMediumFamily;

  @Deprecated('Use titleMedium instead')
  TextStyle get subtitle1 => typography.titleMedium;

  @Deprecated('Use titleSmallFamily instead')
  String get subtitle2Family => typography.titleSmallFamily;

  @Deprecated('Use titleSmall instead')
  TextStyle get subtitle2 => typography.titleSmall;

  @Deprecated('Use bodyMediumFamily instead')
  String get bodyText1Family => typography.bodyMediumFamily;

  @Deprecated('Use bodyMedium instead')
  TextStyle get bodyText1 => typography.bodyMedium;

  @Deprecated('Use bodySmallFamily instead')
  String get bodyText2Family => typography.bodySmallFamily;

  @Deprecated('Use bodySmall instead')
  TextStyle get bodyText2 => typography.bodySmall;

  String get displayLargeFamily => typography.displayLargeFamily;

  TextStyle get displayLarge => typography.displayLarge;

  String get displayMediumFamily => typography.displayMediumFamily;

  TextStyle get displayMedium => typography.displayMedium;

  String get displaySmallFamily => typography.displaySmallFamily;

  TextStyle get displaySmall => typography.displaySmall;

  String get headlineLargeFamily => typography.headlineLargeFamily;

  TextStyle get headlineLarge => typography.headlineLarge;

  String get headlineMediumFamily => typography.headlineMediumFamily;

  TextStyle get headlineMedium => typography.headlineMedium;

  String get headlineSmallFamily => typography.headlineSmallFamily;

  TextStyle get headlineSmall => typography.headlineSmall;

  String get titleLargeFamily => typography.titleLargeFamily;

  TextStyle get titleLarge => typography.titleLarge;

  String get titleMediumFamily => typography.titleMediumFamily;

  TextStyle get titleMedium => typography.titleMedium;

  String get titleSmallFamily => typography.titleSmallFamily;

  TextStyle get titleSmall => typography.titleSmall;

  String get labelLargeFamily => typography.labelLargeFamily;

  TextStyle get labelLarge => typography.labelLarge;

  String get labelMediumFamily => typography.labelMediumFamily;

  TextStyle get labelMedium => typography.labelMedium;

  String get labelSmallFamily => typography.labelSmallFamily;

  TextStyle get labelSmall => typography.labelSmall;

  String get bodyLargeFamily => typography.bodyLargeFamily;

  TextStyle get bodyLarge => typography.bodyLarge;

  String get bodyMediumFamily => typography.bodyMediumFamily;

  TextStyle get bodyMedium => typography.bodyMedium;

  String get bodySmallFamily => typography.bodySmallFamily;

  TextStyle get bodySmall => typography.bodySmall;

  Typography get typography => {
    DeviceSize.mobile: MobileTypography(this),
    DeviceSize.tablet: TabletTypography(this),
    DeviceSize.desktop: DesktopTypography(this),
  }[deviceSize]!;
}

DeviceSize getDeviceSize(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  if (width < 479) {
    return DeviceSize.mobile;
  } else if (width < 991) {
    return DeviceSize.tablet;
  } else {
    return DeviceSize.desktop;
  }
}

class LightModeTheme extends FlutterFlowTheme {
  @Deprecated('Use primary instead')
  Color get primaryColor => primary;

  @Deprecated('Use secondary instead')
  Color get secondaryColor => secondary;

  @Deprecated('Use tertiary instead')
  Color get tertiaryColor => tertiary;

  late Color primary = const Color(0xFFFFBF00);
  late Color secondary = const Color(0xFFF6BF22);
  late Color tertiary = const Color(0xFFF6BF33);
  late Color alternate = const Color(0xFFDDDDDD);
  late Color primaryText = const Color(0xFF000000);
  late Color secondaryText = const Color(0xFF292929);
  late Color primaryBackground = const Color(0xFFFAFAFA);
  late Color secondaryBackground = const Color(0xFFF1F1F1);
  late Color accent1 = const Color(0xFF14213D);
  late Color accent2 = const Color(0xFFE6DD4E);
  late Color accent3 = const Color(0xFFE5E5E5);
  late Color accent4 = const Color(0xFF1E1F25);
  late Color success = const Color(0xFF00FF00);
  late Color warning = const Color(0xFFFF6100);
  late Color error = const Color(0xFFFF0010);
  late Color info = const Color(0xFF14181B);

  late Color customColor1 = const Color(0xFFE6DFF1);
  late Color customColor2 = const Color(0xFF212325);
  late Color customColor3 = const Color(0xFFD0C7BA);
  late Color customColor4 = const Color(0xFFACD1BF);
  late Color customColor5 = const Color(0xFF000000);
  late Color customColor6 = const Color(0xFFFFFFFF);
  late Color accentDict1 = const Color(0xFFFFD4AF);
  late Color accentDict2 = const Color(0xFFFFC0CF);
  late Color accentDict3 = const Color(0xFFB555CB);
  late Color accentDict4 = const Color(0xFF64BDCF);
  late Color accentDict5 = const Color(0xFF58B878);
  late Color accentDict6 = const Color(0xFFCFC33B);
  late Color accentDict7 = const Color(0xFFC9874F);
  late Color accentDict8 = const Color(0xFFCA5C77);
  late Color buttonShadow = const Color(0xFF163959);
  late Color buttonShadow2 = const Color(0xFF3E1674);
  late Color gradient1 = const Color(0xFFBA5DA2);
  late Color gradient2 = const Color(0xFF714AB4);
  late Color accentDict11 = const Color(0xFFEAB7F6);
  late Color accentDict22 = const Color(0xFFB7EBF6);
  late Color accentDict33 = const Color(0xFFB7F6CC);
  late Color accentDict44 = const Color(0xFFF6ED8E);
}

abstract class Typography {
  String get displayLargeFamily;

  TextStyle get displayLarge;

  String get displayMediumFamily;

  TextStyle get displayMedium;

  String get displaySmallFamily;

  TextStyle get displaySmall;

  String get headlineLargeFamily;

  TextStyle get headlineLarge;

  String get headlineMediumFamily;

  TextStyle get headlineMedium;

  String get headlineSmallFamily;

  TextStyle get headlineSmall;

  String get titleLargeFamily;

  TextStyle get titleLarge;

  String get titleMediumFamily;

  TextStyle get titleMedium;

  String get titleSmallFamily;

  TextStyle get titleSmall;

  String get labelLargeFamily;

  TextStyle get labelLarge;

  String get labelMediumFamily;

  TextStyle get labelMedium;

  String get labelSmallFamily;

  TextStyle get labelSmall;

  String get bodyLargeFamily;

  TextStyle get bodyLarge;

  String get bodyMediumFamily;

  TextStyle get bodyMedium;

  String get bodySmallFamily;

  TextStyle get bodySmall;
}

class MobileTypography extends Typography {
  MobileTypography(this.theme);

  final FlutterFlowTheme theme;

  String get displayLargeFamily => 'Instrument Sans';

  TextStyle get displayLarge => GoogleFonts.getFont(
    'Instrument Sans',
    color: theme.primaryText,
    fontWeight: FontWeight.w600,
    fontSize: 64.0,
  );

  String get displayMediumFamily => 'Instrument Sans';

  TextStyle get displayMedium => GoogleFonts.getFont(
    'Instrument Sans',
    color: theme.primaryText,
    fontWeight: FontWeight.w600,
    fontSize: 44.0,
  );

  String get displaySmallFamily => 'Instrument Sans';

  TextStyle get displaySmall => GoogleFonts.getFont(
    'Instrument Sans',
    color: theme.primaryText,
    fontWeight: FontWeight.w600,
    fontSize: 36.0,
  );

  String get headlineLargeFamily => 'Instrument Sans';

  TextStyle get headlineLarge => GoogleFonts.getFont(
    'Instrument Sans',
    color: theme.primaryText,
    fontWeight: FontWeight.w600,
    fontSize: 32.0,
  );

  String get headlineMediumFamily => 'Instrument Sans';

  TextStyle get headlineMedium => GoogleFonts.getFont(
    'Instrument Sans',
    color: theme.primaryText,
    fontWeight: FontWeight.w600,
    fontSize: 28.0,
  );

  String get headlineSmallFamily => 'Instrument Sans';

  TextStyle get headlineSmall => GoogleFonts.getFont(
    'Instrument Sans',
    color: theme.primaryText,
    fontWeight: FontWeight.w600,
    fontSize: 24.0,
  );

  String get titleLargeFamily => 'Instrument Sans';

  TextStyle get titleLarge => GoogleFonts.getFont(
    'Instrument Sans',
    color: theme.primaryText,
    fontWeight: FontWeight.w600,
    fontSize: 20.0,
  );

  String get titleMediumFamily => 'Instrument Sans';

  TextStyle get titleMedium => GoogleFonts.getFont(
    'Instrument Sans',
    color: theme.primaryText,
    fontWeight: FontWeight.w600,
    fontSize: 18.0,
  );

  String get titleSmallFamily => 'Instrument Sans';

  TextStyle get titleSmall => GoogleFonts.getFont(
    'Instrument Sans',
    color: theme.primaryText,
    fontWeight: FontWeight.w600,
    fontSize: 16.0,
  );

  String get labelLargeFamily => 'Instrument Sans';

  TextStyle get labelLarge => GoogleFonts.getFont(
    'Instrument Sans',
    color: theme.secondaryText,
    fontWeight: FontWeight.normal,
    fontSize: 16.0,
  );

  String get labelMediumFamily => 'Instrument Sans';

  TextStyle get labelMedium => GoogleFonts.getFont(
    'Instrument Sans',
    color: theme.secondaryText,
    fontWeight: FontWeight.normal,
    fontSize: 14.0,
  );

  String get labelSmallFamily => 'Instrument Sans';

  TextStyle get labelSmall => GoogleFonts.getFont(
    'Instrument Sans',
    color: theme.secondaryText,
    fontWeight: FontWeight.normal,
    fontSize: 12.0,
  );

  String get bodyLargeFamily => 'Instrument Sans';

  TextStyle get bodyLarge => GoogleFonts.getFont(
    'Instrument Sans',
    color: theme.primaryText,
    fontWeight: FontWeight.normal,
    fontSize: 16.0,
  );

  String get bodyMediumFamily => 'Instrument Sans';

  TextStyle get bodyMedium => GoogleFonts.getFont(
    'Instrument Sans',
    color: theme.primaryText,
    fontWeight: FontWeight.normal,
    fontSize: 14.0,
  );

  String get bodySmallFamily => 'Instrument Sans';

  TextStyle get bodySmall => GoogleFonts.getFont(
    'Instrument Sans',
    color: theme.primaryText,
    fontWeight: FontWeight.normal,
    fontSize: 12.0,
  );
}

class TabletTypography extends Typography {
  TabletTypography(this.theme);

  final FlutterFlowTheme theme;

  String get displayLargeFamily => 'Instrument Sans';

  TextStyle get displayLarge => GoogleFonts.getFont(
    'Instrument Sans',
    color: theme.primaryText,
    fontWeight: FontWeight.w600,
    fontSize: 64.0,
  );

  String get displayMediumFamily => 'Instrument Sans';

  TextStyle get displayMedium => GoogleFonts.getFont(
    'Instrument Sans',
    color: theme.primaryText,
    fontWeight: FontWeight.w600,
    fontSize: 44.0,
  );

  String get displaySmallFamily => 'Instrument Sans';

  TextStyle get displaySmall => GoogleFonts.getFont(
    'Instrument Sans',
    color: theme.primaryText,
    fontWeight: FontWeight.w600,
    fontSize: 36.0,
  );

  String get headlineLargeFamily => 'Instrument Sans';

  TextStyle get headlineLarge => GoogleFonts.getFont(
    'Instrument Sans',
    color: theme.primaryText,
    fontWeight: FontWeight.w600,
    fontSize: 32.0,
  );

  String get headlineMediumFamily => 'Instrument Sans';

  TextStyle get headlineMedium => GoogleFonts.getFont(
    'Instrument Sans',
    color: theme.primaryText,
    fontWeight: FontWeight.w600,
    fontSize: 28.0,
  );

  String get headlineSmallFamily => 'Instrument Sans';

  TextStyle get headlineSmall => GoogleFonts.getFont(
    'Instrument Sans',
    color: theme.primaryText,
    fontWeight: FontWeight.w600,
    fontSize: 24.0,
  );

  String get titleLargeFamily => 'Instrument Sans';

  TextStyle get titleLarge => GoogleFonts.getFont(
    'Instrument Sans',
    color: theme.primaryText,
    fontWeight: FontWeight.w600,
    fontSize: 20.0,
  );

  String get titleMediumFamily => 'Instrument Sans';

  TextStyle get titleMedium => GoogleFonts.getFont(
    'Instrument Sans',
    color: theme.primaryText,
    fontWeight: FontWeight.w600,
    fontSize: 18.0,
  );

  String get titleSmallFamily => 'Instrument Sans';

  TextStyle get titleSmall => GoogleFonts.getFont(
    'Instrument Sans',
    color: theme.primaryText,
    fontWeight: FontWeight.w600,
    fontSize: 16.0,
  );

  String get labelLargeFamily => 'Instrument Sans';

  TextStyle get labelLarge => GoogleFonts.getFont(
    'Instrument Sans',
    color: theme.secondaryText,
    fontWeight: FontWeight.normal,
    fontSize: 16.0,
  );

  String get labelMediumFamily => 'Instrument Sans';

  TextStyle get labelMedium => GoogleFonts.getFont(
    'Instrument Sans',
    color: theme.secondaryText,
    fontWeight: FontWeight.normal,
    fontSize: 14.0,
  );

  String get labelSmallFamily => 'Instrument Sans';

  TextStyle get labelSmall => GoogleFonts.getFont(
    'Instrument Sans',
    color: theme.secondaryText,
    fontWeight: FontWeight.normal,
    fontSize: 12.0,
  );

  String get bodyLargeFamily => 'Instrument Sans';

  TextStyle get bodyLarge => GoogleFonts.getFont(
    'Instrument Sans',
    color: theme.primaryText,
    fontWeight: FontWeight.normal,
    fontSize: 16.0,
  );

  String get bodyMediumFamily => 'Instrument Sans';

  TextStyle get bodyMedium => GoogleFonts.getFont(
    'Instrument Sans',
    color: theme.primaryText,
    fontWeight: FontWeight.normal,
    fontSize: 14.0,
  );

  String get bodySmallFamily => 'Instrument Sans';

  TextStyle get bodySmall => GoogleFonts.getFont(
    'Instrument Sans',
    color: theme.primaryText,
    fontWeight: FontWeight.normal,
    fontSize: 12.0,
  );
}

class DesktopTypography extends Typography {
  DesktopTypography(this.theme);

  final FlutterFlowTheme theme;

  String get displayLargeFamily => 'Instrument Sans';

  TextStyle get displayLarge => GoogleFonts.getFont(
    'Instrument Sans',
    color: theme.primaryText,
    fontWeight: FontWeight.w600,
    fontSize: 64.0,
  );

  String get displayMediumFamily => 'Instrument Sans';

  TextStyle get displayMedium => GoogleFonts.getFont(
    'Instrument Sans',
    color: theme.primaryText,
    fontWeight: FontWeight.w600,
    fontSize: 44.0,
  );

  String get displaySmallFamily => 'Instrument Sans';

  TextStyle get displaySmall => GoogleFonts.getFont(
    'Instrument Sans',
    color: theme.primaryText,
    fontWeight: FontWeight.w600,
    fontSize: 36.0,
  );

  String get headlineLargeFamily => 'Instrument Sans';

  TextStyle get headlineLarge => GoogleFonts.getFont(
    'Instrument Sans',
    color: theme.primaryText,
    fontWeight: FontWeight.w600,
    fontSize: 32.0,
  );

  String get headlineMediumFamily => 'Instrument Sans';

  TextStyle get headlineMedium => GoogleFonts.getFont(
    'Instrument Sans',
    color: theme.primaryText,
    fontWeight: FontWeight.w600,
    fontSize: 28.0,
  );

  String get headlineSmallFamily => 'Instrument Sans';

  TextStyle get headlineSmall => GoogleFonts.getFont(
    'Instrument Sans',
    color: theme.primaryText,
    fontWeight: FontWeight.w600,
    fontSize: 24.0,
  );

  String get titleLargeFamily => 'Instrument Sans';

  TextStyle get titleLarge => GoogleFonts.getFont(
    'Instrument Sans',
    color: theme.primaryText,
    fontWeight: FontWeight.w600,
    fontSize: 20.0,
  );

  String get titleMediumFamily => 'Instrument Sans';

  TextStyle get titleMedium => GoogleFonts.getFont(
    'Instrument Sans',
    color: theme.primaryText,
    fontWeight: FontWeight.w600,
    fontSize: 18.0,
  );

  String get titleSmallFamily => 'Instrument Sans';

  TextStyle get titleSmall => GoogleFonts.getFont(
    'Instrument Sans',
    color: theme.primaryText,
    fontWeight: FontWeight.w600,
    fontSize: 16.0,
  );

  String get labelLargeFamily => 'Instrument Sans';

  TextStyle get labelLarge => GoogleFonts.getFont(
    'Instrument Sans',
    color: theme.secondaryText,
    fontWeight: FontWeight.normal,
    fontSize: 16.0,
  );

  String get labelMediumFamily => 'Instrument Sans';

  TextStyle get labelMedium => GoogleFonts.getFont(
    'Instrument Sans',
    color: theme.secondaryText,
    fontWeight: FontWeight.normal,
    fontSize: 14.0,
  );

  String get labelSmallFamily => 'Instrument Sans';

  TextStyle get labelSmall => GoogleFonts.getFont(
    'Instrument Sans',
    color: theme.secondaryText,
    fontWeight: FontWeight.normal,
    fontSize: 12.0,
  );

  String get bodyLargeFamily => 'Instrument Sans';

  TextStyle get bodyLarge => GoogleFonts.getFont(
    'Instrument Sans',
    color: theme.primaryText,
    fontWeight: FontWeight.normal,
    fontSize: 16.0,
  );

  String get bodyMediumFamily => 'Instrument Sans';

  TextStyle get bodyMedium => GoogleFonts.getFont(
    'Instrument Sans',
    color: theme.primaryText,
    fontWeight: FontWeight.normal,
    fontSize: 14.0,
  );

  String get bodySmallFamily => 'Instrument Sans';

  TextStyle get bodySmall => GoogleFonts.getFont(
    'Instrument Sans',
    color: theme.primaryText,
    fontWeight: FontWeight.normal,
    fontSize: 12.0,
  );
}

class DarkModeTheme extends FlutterFlowTheme {
  @Deprecated('Use primary instead')
  Color get primaryColor => primary;

  @Deprecated('Use secondary instead')
  Color get secondaryColor => secondary;

  @Deprecated('Use tertiary instead')
  Color get tertiaryColor => tertiary;

  late Color primary = const Color(0xFFFFBF00);
  late Color secondary = const Color(0xFFF6BF22);
  late Color tertiary = const Color(0xFFF6BF33);
  late Color alternate = const Color(0xFF333333);
  late Color primaryText = const Color(0xFFFFFFFF);
  late Color secondaryText = const Color(0xFFDDDDDD);
  late Color primaryBackground = const Color(0xFF121212);
  late Color secondaryBackground = const Color(0xFF1E1E1E);
  late Color accent1 = const Color(0xFF14213D);
  late Color accent2 = const Color(0xFFE6DD4E);
  late Color accent3 = const Color(0xFFE5E5E5);
  late Color accent4 = const Color(0xFF1E1F25);
  late Color success = const Color(0xFF00FF00);
  late Color warning = const Color(0xFFFF6100);
  late Color error = const Color(0xFFFF0010);
  late Color info = const Color(0xFFFFFFFF);

  late Color customColor1 = const Color(0xFFE6DFF1);
  late Color customColor2 = const Color(0xFF212325);
  late Color customColor3 = const Color(0xFFD0C7BA);
  late Color customColor4 = const Color(0xFFACD1BF);
  late Color customColor5 = const Color(0xFF000000);
  late Color customColor6 = const Color(0xFFFFFFFF);
  late Color accentDict1 = const Color(0xFFFFD4AF);
  late Color accentDict2 = const Color(0xFFFFC0CF);
  late Color accentDict3 = const Color(0xFFB555CB);
  late Color accentDict4 = const Color(0xFF64BDCF);
  late Color accentDict5 = const Color(0xFF58B878);
  late Color accentDict6 = const Color(0xFFCFC33B);
  late Color accentDict7 = const Color(0xFFC9874F);
  late Color accentDict8 = const Color(0xFFCA5C77);
  late Color buttonShadow = const Color(0xFF163959);
  late Color buttonShadow2 = const Color(0xFF3E1674);
  late Color gradient1 = const Color(0xFFBA5DA2);
  late Color gradient2 = const Color(0xFF714AB4);
  late Color accentDict11 = const Color(0xFFEAB7F6);
  late Color accentDict22 = const Color(0xFFB7EBF6);
  late Color accentDict33 = const Color(0xFFB7F6CC);
  late Color accentDict44 = const Color(0xFFF6ED8E);
}

extension TextStyleHelper on TextStyle {
  TextStyle override({
    String? fontFamily,
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
    double? letterSpacing,
    FontStyle? fontStyle,
    bool useGoogleFonts = true,
    TextDecoration? decoration,
    double? lineHeight,
    List<Shadow>? shadows,
  }) => useGoogleFonts
      ? GoogleFonts.getFont(
          fontFamily!,
          color: color ?? this.color,
          fontSize: fontSize ?? this.fontSize,
          letterSpacing: letterSpacing ?? this.letterSpacing,
          fontWeight: fontWeight ?? this.fontWeight,
          fontStyle: fontStyle ?? this.fontStyle,
          decoration: decoration,
          height: lineHeight,
          shadows: shadows,
        )
      : copyWith(
          fontFamily: fontFamily,
          color: color,
          fontSize: fontSize,
          letterSpacing: letterSpacing,
          fontWeight: fontWeight,
          fontStyle: fontStyle,
          decoration: decoration,
          height: lineHeight,
          shadows: shadows,
        );
}
