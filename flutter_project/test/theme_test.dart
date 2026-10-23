import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lahore_speedo_bus_guide/app/theme/app_colors.dart';
import 'package:lahore_speedo_bus_guide/app/theme/app_palette.dart';
import 'package:lahore_speedo_bus_guide/app/theme/app_tokens.dart';
import 'package:lahore_speedo_bus_guide/app/theme/theme_controller.dart';
import 'package:lahore_speedo_bus_guide/core/storage/preferences_store.dart';

void main() {
  group('recovered design tokens', () {
    test('SPACING', () {
      expect(Tokens.spaceXs, 4);
      expect(Tokens.spaceSm, 8);
      expect(Tokens.spaceMd, 16);
      expect(Tokens.spaceLg, 24);
      expect(Tokens.spaceXl, 32);
      expect(Tokens.spaceXxl, 48);
    });

    test('FONT_SIZE', () {
      expect(Tokens.fontXs, 10);
      expect(Tokens.fontSm, 12);
      expect(Tokens.fontMd, 14);
      expect(Tokens.fontBase, 16);
      expect(Tokens.fontLg, 18);
      expect(Tokens.fontXl, 22);
      expect(Tokens.fontXxl, 28);
      expect(Tokens.fontXxxl, 36);
    });

    test('BORDER_RADIUS', () {
      expect(Tokens.radiusSm, 6);
      expect(Tokens.radiusMd, 10);
      expect(Tokens.radiusLg, 16);
      expect(Tokens.radiusXl, 24);
      expect(Tokens.radiusFull, 999);
    });
  });

  group('palettes', () {
    test('light values come from the reference artwork', () {
      expect(AppPalette.light.primary.toARGB32(), 0xFF3B7306);
      expect(AppPalette.light.primaryBright.toARGB32(), 0xFF83A034);
      expect(AppPalette.light.accent.toARGB32(), 0xFF9BB224);
      expect(AppPalette.light.background.toARGB32(), 0xFFF3F8E4);
      expect(AppPalette.light.card.toARGB32(), 0xFFFFFFFF);
      expect(AppPalette.light.border.toARGB32(), 0xFFDFEBC8);
      expect(AppPalette.light.text.toARGB32(), 0xFF1E2A10);
      expect(AppPalette.light.textSecondary.toARGB32(), 0xFF5F7346);
    });

    test('dark values come from the reference artwork', () {
      expect(AppPalette.dark.primary.toARGB32(), 0xFF8FBB2A);
      expect(AppPalette.dark.background.toARGB32(), 0xFF101808);
      expect(AppPalette.dark.backgroundAlt.toARGB32(), 0xFF1A2610);
      expect(AppPalette.dark.card.toARGB32(), 0xFF1E2A14);
      expect(AppPalette.dark.border.toARGB32(), 0xFF33421F);
      expect(AppPalette.dark.text.toARGB32(), 0xFFEAF2DC);
      expect(AppPalette.dark.textSecondary.toARGB32(), 0xFFA9BA8C);
    });

    test('category colours', () {
      expect(AppColors.speedoColor.toARGB32(), 0xFFC2410C);
      expect(AppColors.metroColor.toARGB32(), 0xFF3F7FB5);
      expect(AppColors.orangeLineColor.toARGB32(), 0xFFD98A0B);
      expect(AppColors.electricColor.toARGB32(), 0xFF4C8B1B);
    });
  });

  group('ThemeController', () {
    test('defaults to system / light', () {
      final c = ThemeController(MemoryPreferencesStore());
      expect(c.state.preference, ThemePreference.system);
      expect(c.state.isDark, false);
      expect(c.state.themeMode, ThemeMode.system);
    });

    test('follows the platform brightness when preference is system', () {
      final c = ThemeController(MemoryPreferencesStore());
      c.onPlatformBrightnessChanged(Brightness.dark);
      expect(c.state.isDark, true);
      expect(c.state.palette.background.toARGB32(), 0xFF101808);
    });

    test('toggleTheme persists the chosen preference', () async {
      final store = MemoryPreferencesStore();
      final c = ThemeController(store);
      await c.toggleTheme();
      expect(c.state.preference, ThemePreference.dark);
      expect(store.getString('themePreference'), 'dark');

      c.onPlatformBrightnessChanged(Brightness.light);
      expect(c.state.isDark, true, reason: 'explicit dark beats the platform');
    });

    test('setPreference round-trips through the store', () async {
      final store = MemoryPreferencesStore();
      final c = ThemeController(store);
      await c.setPreference(ThemePreference.light);
      expect(store.getString('themePreference'), 'light');
      c.onPlatformBrightnessChanged(Brightness.dark);
      expect(c.state.isDark, false);
    });
  });
}
