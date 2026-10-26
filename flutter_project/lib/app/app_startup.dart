import 'dart:async';

import 'package:flutter/material.dart';

import '../data/repositories/routes_repository.dart';
import '../data/repositories/stop_repository.dart';
import '../features/launch/launch_screen.dart';

/// Loads the bundled offline data used by every tab.
///
/// Loading is intentionally non-fatal. A malformed or unavailable asset must
/// never leave the user on a blank launch screen; the screens themselves
/// provide their empty states.
Future<void> warmAppData() async {
  try {
    await RoutesRepository.instance.ensureLoaded();
    await StopRepository.instance.ensureLoaded();
  } catch (error, stack) {
    debugPrint('Could not preload the route dataset: $error');
    debugPrintStack(stackTrace: stack);
  }
}

/// Holds the branded launch screen until the first app frame is ready, then
/// hands over to the route guide with a short cross-fade and scale.
class AppStartupGate extends StatefulWidget {
  const AppStartupGate({
    required this.child,
    this.initialize = warmAppData,
    this.minimumDuration = const Duration(milliseconds: 1100),
    super.key,
  });

  final Widget child;
  final Future<void> Function() initialize;
  final Duration minimumDuration;

  @override
  State<AppStartupGate> createState() => _AppStartupGateState();
}

class _AppStartupGateState extends State<AppStartupGate>
    with SingleTickerProviderStateMixin {
  late final AnimationController _transitionController;
  late final CurvedAnimation _transition;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _transitionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 620),
    );
    _transition = CurvedAnimation(
      parent: _transitionController,
      curve: Curves.easeOutCubic,
    );
    unawaited(_initialize());
  }

  Future<void> _initialize() async {
    final stopwatch = Stopwatch()..start();
    try {
      await widget.initialize();
    } catch (error, stack) {
      debugPrint('App initialization failed; continuing to the app: $error');
      debugPrintStack(stackTrace: stack);
    }
    stopwatch.stop();

    final remaining = widget.minimumDuration - stopwatch.elapsed;
    if (remaining > Duration.zero) {
      await Future<void>.delayed(remaining);
    }
    if (!mounted) return;

    setState(() => _ready = true);
    _transitionController.forward();
  }

  @override
  void dispose() {
    _transitionController.dispose();
    _transition.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _transition,
      builder: (context, child) {
        final progress = _transition.value;
        final app = child ?? const SizedBox.shrink();
        if (_ready && progress >= 1) {
          return Directionality(textDirection: TextDirection.ltr, child: app);
        }
        return MediaQuery(
          data: MediaQueryData.fromView(View.of(context)),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Opacity(
                  opacity: (1 - progress).clamp(0.0, 1.0),
                  child: Transform.scale(
                    scale: 1 + (progress * 0.035),
                    child: const LaunchScreen(),
                  ),
                ),
                if (_ready)
                  Opacity(
                    opacity: progress,
                    child: Transform.scale(
                      scale: 0.985 + (progress * 0.015),
                      child: app,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
      child: widget.child,
    );
  }
}
