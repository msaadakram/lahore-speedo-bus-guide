import 'package:flutter/material.dart';

import '../../app/theme/app_palette.dart';
import '../../app/theme/app_tokens.dart';
import '../../features/home/home_screen.dart';
import '../../features/nearby/nearby_screen.dart';
import '../../features/schedule/schedule_screen.dart';
import '../../features/settings/settings_screen.dart';
import 'app_widgets.dart';

/// Bottom navigation bar recreated from `BottomTabs.tsx` and upgraded to the
/// app's soft, elevated design language.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    required this.currentIndex,
    required this.onSelect,
    super.key,
  });

  final int currentIndex;
  final ValueChanged<int> onSelect;

  static const tabs = <({String label, IconData active, IconData inactive})>[
    (label: 'Home', active: Icons.home_rounded, inactive: Icons.home_outlined),
    (
      label: 'Nearby',
      active: Icons.location_on_rounded,
      inactive: Icons.location_on_outlined,
    ),
    (
      label: 'Schedule',
      active: Icons.directions_bus_rounded,
      inactive: Icons.directions_bus_outlined,
    ),
    (
      label: 'Settings',
      active: Icons.settings_rounded,
      inactive: Icons.settings_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final palette = AppPaletteScope.paletteOf(context);
    return DecoratedBox(
      decoration: BoxDecoration(gradient: palette.canvasGradient),
      child: Container(
        decoration: BoxDecoration(
          color: palette.card.withValues(alpha: .98),
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(Tokens.shapeLg),
          ),
          border: Border(top: BorderSide(color: palette.border)),
          boxShadow: [
            BoxShadow(
              color: palette.shadow,
              blurRadius: 26,
              offset: const Offset(0, -10),
              spreadRadius: -8,
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 74,
            child: Row(
              children: [
                for (var i = 0; i < tabs.length; i++)
                  Expanded(
                    child: _NavItem(
                      tab: tabs[i],
                      selected: i == currentIndex,
                      palette: palette,
                      onTap: () => onSelect(i),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.tab,
    required this.selected,
    required this.palette,
    required this.onTap,
  });

  final ({String label, IconData active, IconData inactive}) tab;
  final bool selected;
  final AppPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? palette.primary : palette.textSecondary;
    return AppPressable(
      onPressed: onTap,
      borderless: true,
      selected: selected,
      semanticLabel: '${tab.label} tab',
      borderRadius: BorderRadius.circular(Tokens.shapePill),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(
              horizontal: Tokens.spaceMd,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: selected
                  ? palette.primary.withValues(alpha: .16)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(Tokens.shapePill),
            ),
            child: Icon(
              selected ? tab.active : tab.inactive,
              size: 24,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            style: TextStyle(
              fontSize: Tokens.fontXs,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              color: color,
              letterSpacing: selected ? .2 : 0,
            ),
            child: Text(
              tab.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Hosts the four tabs.
///
/// Tabs are instantiated lazily, then kept alive in an [IndexedStack]. This
/// avoids asking for location permission before the user opens Nearby, while
/// also preserving each tab's scroll position, selected category and journey
/// selections when the user moves between tabs.
class MainTabsHost extends StatefulWidget {
  const MainTabsHost({super.key});

  @override
  State<MainTabsHost> createState() => _MainTabsHostState();
}

class _MainTabsHostState extends State<MainTabsHost> {
  int _index = 0;
  final List<Widget?> _builtTabs = [const HomeScreen(), null, null, null];

  void _select(int i) {
    if (i == _index || i < 0 || i >= _builtTabs.length) return;
    setState(() {
      _index = i;
      _builtTabs[i] ??= switch (i) {
        1 => const NearbyScreen(),
        2 => const ScheduleScreen(),
        _ => const SettingsScreen(),
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: false,
      body: IndexedStack(
        index: _index,
        children: [
          for (var i = 0; i < _builtTabs.length; i++)
            _builtTabs[i] ?? const SizedBox.shrink(),
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _index,
        onSelect: _select,
      ),
    );
  }
}
