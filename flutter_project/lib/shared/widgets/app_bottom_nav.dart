import 'package:flutter/material.dart';

import '../../app/theme/app_palette.dart';
import '../../app/theme/app_tokens.dart';
import '../../features/home/home_screen.dart';
import '../../features/nearby/nearby_screen.dart';
import '../../features/schedule/schedule_screen.dart';
import '../../features/settings/settings_screen.dart';
import 'app_widgets.dart';

/// Bottom navigation bar recreated from `BottomTabs.tsx` (Metro module 557):
/// Paper `BottomNavigation.Bar`, `compact`, white active pill, primary active
/// colour, `textSecondary` inactive, `card` background and a top hairline.
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
    return Container(
      decoration: BoxDecoration(
        color: palette.card,
        border: Border(top: BorderSide(color: palette.border)),
        boxShadow: [
          BoxShadow(
            color: palette.shadow,
            blurRadius: 20,
            offset: const Offset(0, -6),
            spreadRadius: -6,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 68,
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: selected
                  ? palette.primary.withValues(alpha: 0.16)
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
          Text(
            tab.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: Tokens.fontXs,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Hosts the four tabs with a `GlobalKey<NavigatorState>`-free index-based
/// switcher that mirrors the original bottom-tab behaviour.
class MainTabsHost extends StatefulWidget {
  const MainTabsHost({super.key});

  @override
  State<MainTabsHost> createState() => _MainTabsHostState();
}

class _MainTabsHostState extends State<MainTabsHost> {
  int _index = 0;

  void _select(int i) {
    if (i == _index) return;
    setState(() => _index = i);
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPaletteScope.paletteOf(context);
    final page = <Widget>[
      const HomeScreen(),
      const NearbyScreen(),
      const ScheduleScreen(),
      const SettingsScreen(),
    ][_index];

    return Scaffold(
      extendBody: false,
      body: DecoratedBox(
        decoration: BoxDecoration(gradient: palette.canvasGradient),
        child: page,
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _index,
        onSelect: _select,
      ),
    );
  }
}
