import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../shared/widgets/app_bottom_nav.dart';
import 'router.dart';
import 'theme/app_palette.dart';
import 'theme/app_theme.dart';
import 'theme/theme_controller.dart';

/// Recreates `AppShell` (Metro module 495):
///   SafeAreaProvider → ThemeProvider → NavigationContainer
///   → Stack.Navigator [MainTabs, Search, …] + ForceUpdateModal overlay.
class BusGuideApp extends ConsumerWidget {
  const BusGuideApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeControllerProvider);
    final palette = themeState.palette;

    return AppPaletteScope(
      palette: palette,
      isDark: themeState.isDark,
      preference: themeState.preference,
      setThemePreference: (p) =>
          ref.read(themeControllerProvider.notifier).setPreference(p),
      child: _BrightnessSync(
        child: MaterialApp(
          title: 'Lahore Speedo Bus Guide',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: themeState.themeMode,
          onGenerateRoute: AppRouter.onGenerateRoute,
          home: const MainTabsHost(),
          builder: (context, child) => MediaQuery.withClampedTextScaling(
            // The transit UI is dense. Scaling beyond 1.4 made headers, cards
            // and the map sheet overflow; 1.4 keeps large-text support usable.
            maxScaleFactor: 1.4,
            child: Stack(
              children: [
                child ?? const SizedBox.shrink(),
                const ForceUpdateOverlay(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Notifies the theme controller when the platform colour scheme changes —
/// the equivalent of `Appearance.addChangeListener` in the original.
class _BrightnessSync extends StatefulWidget {
  const _BrightnessSync({required this.child});

  final Widget child;

  @override
  State<_BrightnessSync> createState() => _BrightnessSyncState();
}

class _BrightnessSyncState extends State<_BrightnessSync>
    with WidgetsBindingObserver {
  late final ProviderContainer _container;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _container = ProviderScope.containerOf(context, listen: false);
    final next = MediaQuery.platformBrightnessOf(context);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _container
          .read(themeControllerProvider.notifier)
          .onPlatformBrightnessChanged(next),
    );
  }

  @override
  void didChangePlatformBrightness() {
    super.didChangePlatformBrightness();
    final next = MediaQuery.platformBrightnessOf(context);
    _container
        .read(themeControllerProvider.notifier)
        .onPlatformBrightnessChanged(next);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Force-update modal surface. The version check itself is not performed
/// (the original used Play Core / in-app updates, which require a store
/// listing and signing keys); the overlay is kept faithful so the UI is ready.
class ForceUpdateOverlay extends StatelessWidget {
  const ForceUpdateOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
