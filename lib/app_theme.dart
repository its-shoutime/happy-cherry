import 'package:flutter/material.dart';
import 'package:pixel_ui/pixel_ui.dart';

class AppTheme {
  AppTheme._();

  static const Color backgroundPink = Color(0xFFCD96A8);
  static const Color appBarPink = Color(0xFFE8B8C8);
  static const Color textDark = Color(0xFF3D1F2B);
  static const Color textLight = Color(0xFFFFFFFF);
  static const Color borderDark = Color(0xFF5A2A3D);
  static const Color buttonFill = Color(0xFFE07A9C);
  static const Color buttonPressedFill = Color(0xFFB85A78);
  static const Color buttonDisabledFill = Color(0xFF9A7A86);
  static const Color buttonShadow = Color(0xFF5A2A3D);

  static const PixelShapeStyle panelStyle = PixelShapeStyle(
    corners: PixelCorners.lg,
    fillColor: Color(0xFFF2D4DE),
    borderColor: borderDark,
    borderWidth: 1,
    shadow: PixelShadow(offset: Offset(2, 2), color: buttonShadow),
    texture: PixelTexture(
      color: Color(0xFFFFFFFF),
      density: 0.06,
      size: 1,
      seed: 3,
    ),
  );

  static const PixelShapeStyle buttonNormal = PixelShapeStyle(
    corners: PixelCorners.lg,
    fillColor: buttonFill,
    borderColor: borderDark,
    borderWidth: 1,
    shadow: PixelShadow(offset: Offset(1, 1), color: buttonShadow),
  );

  static const PixelShapeStyle buttonPressed = PixelShapeStyle(
    corners: PixelCorners.lg,
    fillColor: buttonPressedFill,
    borderColor: borderDark,
    borderWidth: 1,
  );

  static const PixelShapeStyle buttonDisabled = PixelShapeStyle(
    corners: PixelCorners.lg,
    fillColor: buttonDisabledFill,
    borderColor: Color(0xFF6A5A62),
    borderWidth: 1,
  );

  static const PixelButtonTheme buttonTheme = PixelButtonTheme(
    normalStyle: buttonNormal,
    pressedStyle: buttonPressed,
    disabledStyle: buttonDisabled,
  );

  static const PixelTheme pixelTheme = PixelTheme(
    box: PixelBoxTheme(style: panelStyle),
    button: buttonTheme,
  );

  static ThemeData light() {
    return pixelUiTheme(
      base: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: backgroundPink,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.pink,
          brightness: Brightness.light,
        ),
        textTheme: Typography.blackMountainView.apply(
          fontFamily: PixelText.mulmaruFontFamily,
          package: PixelText.mulmaruPackage,
          bodyColor: textDark,
          displayColor: textDark,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: appBarPink,
          foregroundColor: textDark,
          elevation: 0,
        ),
      ),
      pixelTheme: pixelTheme,
    );
  }

  static ThemeData dark() {
    return pixelUiTheme(
      base: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.pink,
          brightness: Brightness.dark,
        ),
        textTheme: Typography.whiteMountainView.apply(
          fontFamily: PixelText.mulmaruFontFamily,
          package: PixelText.mulmaruPackage,
          bodyColor: textLight,
          displayColor: textLight,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1A1A1A),
          foregroundColor: textLight,
          elevation: 0,
        ),
      ),
      pixelTheme: const PixelTheme(
        box: PixelBoxTheme(style: panelStyle),
        button: PixelButtonTheme(
          normalStyle: PixelShapeStyle(
            corners: PixelCorners.lg,
            fillColor: Color(0xFF8B4A62),
            borderColor: Color(0xFF3D1F2B),
            borderWidth: 1,
            shadow: PixelShadow(offset: Offset(1, 1), color: Color(0xFF2A1018)),
          ),
          pressedStyle: PixelShapeStyle(
            corners: PixelCorners.lg,
            fillColor: Color(0xFF6B3A4D),
            borderColor: Color(0xFF3D1F2B),
            borderWidth: 1,
          ),
          disabledStyle: PixelShapeStyle(
            corners: PixelCorners.lg,
            fillColor: Color(0xFF4A3A42),
            borderColor: Color(0xFF2A2024),
            borderWidth: 1,
          ),
        ),
      ),
    );
  }

  static ThemeData forLightsOff(bool lightsOff) =>
      lightsOff ? dark() : light();

  static TextStyle pixelText({
    required double fontSize,
    required Color color,
    Color? shadowColor,
  }) {
    return PixelText.mulmaru(
      fontSize: fontSize,
      color: color,
      shadowColor: shadowColor,
    );
  }

  static TextStyle buttonLabel(Color color) {
    return PixelText.mulmaru(
      fontSize: 14,
      color: color,
      shadowColor: const Color(0x80000000),
    );
  }

  static Color textColorFor(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? textLight : textDark;
}
