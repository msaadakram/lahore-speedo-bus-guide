import 'package:flutter/material.dart';

import '../data/models/bus_stop.dart';
import '../data/repositories/journey_repository.dart';
import '../features/credits/credits_screen.dart';
import '../features/feedback/feedback_screen.dart';
import '../features/home/home_screen.dart';
import '../features/journey_detail/journey_detail_screen.dart';
import '../features/journey_results/journey_results_screen.dart';
import '../features/map/map_screen.dart';
import '../features/nearby/nearby_screen.dart';
import '../features/privacy/privacy_screen.dart';
import '../features/route_detail/route_detail_screen.dart';
import '../features/schedule/schedule_screen.dart';
import '../features/search/search_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/stop_detail/stop_detail_screen.dart';
import '../features/stop_picker/stop_picker_screen.dart';

/// Route names — one-to-one with the original stack navigator.
abstract final class Routes {
  const Routes._();

  static const mainTabs = 'MainTabs';
  static const search = 'Search';
  static const routeDetail = 'RouteDetail';
  static const stopDetail = 'StopDetail';
  static const map = 'Map';
  static const stopPicker = 'StopPicker';
  static const journeyResults = 'JourneyResults';
  static const journeyDetail = 'JourneyDetail';
  static const credits = 'Credits';
  static const feedback = 'Feedback';
  static const privacyPolicy = 'PrivacyPolicy';
}

/// Tab routes — one-to-one with `BottomTabs.tsx`.
abstract final class Tabs {
  const Tabs._();

  static const home = 'Home';
  static const nearby = 'Nearby';
  static const schedule = 'Schedule';
  static const settings = 'Settings';
}

/// Extra argument payloads keep the API close to the original route params.
class RouteDetailArgs {
  const RouteDetailArgs({required this.routeId, this.color});

  final String routeId;
  final String? color;
}

class StopDetailArgs {
  const StopDetailArgs({required this.stopName});

  final String stopName;
}

class StopPickerArgs {
  const StopPickerArgs({required this.mode, this.title});

  final String mode; // 'from' | 'to'
  final String? title;
}

class JourneyResultsArgs {
  const JourneyResultsArgs({
    required this.fromKey,
    required this.toKey,
    required this.fromName,
    required this.toName,
  });

  final String fromKey;
  final String toKey;
  final String fromName;
  final String toName;
}

class JourneyDetailArgs {
  const JourneyDetailArgs({required this.journey});

  final Journey journey;
}

class MapArgs {
  const MapArgs({this.routeId, this.stopId, this.title, this.color});

  final String? routeId;
  final String? stopId;
  final String? title;

  /// The route's line colour, used for the map polyline.
  final String? color;
}

class AppRouter {
  const AppRouter._();

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final page = _pageFor(settings);
    if (page == null) return null;
    return _fadeThrough(page, settings.name);
  }

  static Widget? _pageFor(RouteSettings settings) {
    final args = settings.arguments;
    switch (settings.name) {
      case Tabs.home:
        return const HomeScreen();
      case Tabs.nearby:
        return const NearbyScreen();
      case Tabs.schedule:
        return const ScheduleScreen();
      case Tabs.settings:
        return const SettingsScreen();
      case Routes.search:
        return const SearchScreen();
      case Routes.routeDetail:
        return RouteDetailScreen(args: args as RouteDetailArgs);
      case Routes.stopDetail:
        return StopDetailScreen(args: args as StopDetailArgs);
      case Routes.map:
        return MapScreen(args: args as MapArgs? ?? const MapArgs());
      case Routes.stopPicker:
        final pickerArgs = args as StopPickerArgs?;
        return StopPickerScreen(
          mode: pickerArgs?.mode ?? 'from',
          title: pickerArgs?.title,
        );
      case Routes.journeyResults:
        return JourneyResultsScreen(args: args as JourneyResultsArgs);
      case Routes.journeyDetail:
        return JourneyDetailScreen(args: args as JourneyDetailArgs);
      case Routes.credits:
        return const CreditsScreen();
      case Routes.feedback:
        return const FeedbackScreen();
      case Routes.privacyPolicy:
        return const PrivacyPolicyScreen();
      default:
        return null;
    }
  }

  /// The original stack animates `slide_from_right`; the tabs use `shift`.
  static Route<dynamic> _fadeThrough(Widget page, String? name) {
    return PageRouteBuilder(
      settings: RouteSettings(name: name),
      pageBuilder: (_, _, _) => page,
      transitionDuration: const Duration(milliseconds: 220),
      reverseTransitionDuration: const Duration(milliseconds: 180),
      transitionsBuilder: (_, animation, _, child) {
        final t = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.06, 0),
            end: Offset.zero,
          ).animate(t),
          child: FadeTransition(opacity: t, child: child),
        );
      },
    );
  }

  /// Route used for the bottom-navigation tabs (no slide animation, like RN's
  /// `shift` behaviour).
  static Route<dynamic> tabRoute(Widget page, String name) {
    return PageRouteBuilder(
      settings: RouteSettings(name: name),
      pageBuilder: (_, _, _) => page,
      transitionDuration: const Duration(milliseconds: 180),
      transitionsBuilder: (_, animation, _, child) =>
          FadeTransition(opacity: animation, child: child),
    );
  }
}

/// Result returned by `StopPickerScreen` — replaces the RN `onSelect` callback.
class StopPickerResult {
  const StopPickerResult(this.stop);

  final BusStop stop;
}
