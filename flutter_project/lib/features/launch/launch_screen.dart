import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Animated surface shown while the offline route index is prepared.
///
/// The launch experience uses the launcher artwork's navy and gold identity.
/// The app itself keeps its green content theme, creating a clear transition
/// from the operating-system splash into Flutter and then into the guide.
class LaunchScreen extends StatefulWidget {
  const LaunchScreen({super.key});

  static const Color navy = Color(0xFF061B45);
  static const Color navyLight = Color(0xFF0B2C61);
  static const Color gold = Color(0xFFFFB300);
  static const Color goldLight = Color(0xFFFFD166);

  @override
  State<LaunchScreen> createState() => _LaunchScreenState();
}

class _LaunchScreenState extends State<LaunchScreen>
    with TickerProviderStateMixin {
  late final AnimationController _entranceController;
  late final AnimationController _routeController;
  late final CurvedAnimation _logoScale;
  late final CurvedAnimation _logoFade;
  late final CurvedAnimation _copyFade;

  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    );
    _routeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    _logoScale = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0, 0.72, curve: Curves.easeOutBack),
    );
    _logoFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0, 0.42, curve: Curves.easeOut),
    );
    _copyFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.32, 0.82, curve: Curves.easeOut),
    );
    _entranceController.forward();
    _routeController.repeat();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (reduceMotion == _reduceMotion) return;
    _reduceMotion = reduceMotion;

    if (reduceMotion) {
      _entranceController
        ..stop()
        ..value = 1;
      _routeController
        ..stop()
        ..value = 0.42;
    } else {
      _entranceController.forward(from: 0);
      _routeController.repeat();
    }
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _routeController.dispose();
    _logoScale.dispose();
    _logoFade.dispose();
    _copyFade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: LaunchScreen.navy,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: ColoredBox(
        color: LaunchScreen.navy,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [LaunchScreen.navyLight, LaunchScreen.navy],
                ),
              ),
            ),
            _AmbientGlow(animation: _routeController),
            AnimatedBuilder(
              animation: _routeController,
              builder: (context, _) => CustomPaint(
                painter: _AmbientRoutePainter(progress: _routeController.value),
              ),
            ),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedBuilder(
                        animation: _entranceController,
                        builder: (context, child) {
                          final scale = 0.82 + (_logoScale.value * 0.18);
                          return Opacity(
                            opacity: _logoFade.value,
                            child: Transform.rotate(
                              angle: (1 - _logoScale.value) * -0.08,
                              child: Transform.scale(
                                scale: scale,
                                child: child,
                              ),
                            ),
                          );
                        },
                        child: Semantics(
                          image: true,
                          label: 'Speedo Bus Route Guide',
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: const Color(0xFF041D48),
                              borderRadius: BorderRadius.circular(46),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x52000000),
                                  blurRadius: 34,
                                  offset: Offset(0, 18),
                                  spreadRadius: -8,
                                ),
                                BoxShadow(
                                  color: Color(0x3DFFB300),
                                  blurRadius: 30,
                                  spreadRadius: -12,
                                ),
                              ],
                            ),
                            child: Image.asset(
                              'assets/images/speedo_logo.png',
                              width: 184,
                              height: 184,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 34),
                      FadeTransition(
                        opacity: _copyFade,
                        child: Column(
                          children: [
                            const Text(
                              'PREPARING YOUR ROUTES',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: LaunchScreen.goldLight,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 2.6,
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: 190,
                              height: 22,
                              child: AnimatedBuilder(
                                animation: _routeController,
                                builder: (context, _) => CustomPaint(
                                  painter: _RouteProgressPainter(
                                    progress: _routeController.value,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Lahore  •  Ready offline',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.66),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A soft gold light that breathes behind the logo.
class _AmbientGlow extends StatelessWidget {
  const _AmbientGlow({required this.animation});

  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final pulse = 0.88 + (math.sin(animation.value * math.pi * 2) * 0.12);
        return Align(
          alignment: const Alignment(0.35, -0.28),
          child: FractionallySizedBox(
            widthFactor: 1.1,
            heightFactor: 0.62,
            child: Transform.scale(
              scale: pulse,
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [Color(0x2EFFB300), Color(0x00FFB300)],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// The faint route behind the mark gives the static launcher identity motion.
class _AmbientRoutePainter extends CustomPainter {
  const _AmbientRoutePainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final route = Path()
      ..moveTo(-30, size.height * 0.38)
      ..cubicTo(
        size.width * 0.22,
        size.height * 0.20,
        size.width * 0.50,
        size.height * 0.58,
        size.width + 30,
        size.height * 0.28,
      );
    canvas.drawPath(
      route,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.055)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    for (final metric in route.computeMetrics()) {
      final travel = (progress * 1.35).clamp(0.0, 1.0);
      canvas.drawPath(
        metric.extractPath(0, metric.length * travel),
        Paint()
          ..color = LaunchScreen.gold.withValues(alpha: 0.22)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      final tangent = metric.getTangentForOffset(metric.length * travel);
      if (tangent != null) {
        canvas.drawCircle(
          tangent.position,
          3.5,
          Paint()..color = LaunchScreen.goldLight.withValues(alpha: 0.72),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _AmbientRoutePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// A route-shaped loading track instead of a generic circular spinner.
class _RouteProgressPainter extends CustomPainter {
  const _RouteProgressPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final route = Path()
      ..moveTo(0, size.height * 0.58)
      ..cubicTo(
        size.width * 0.24,
        size.height * 0.08,
        size.width * 0.43,
        size.height * 0.98,
        size.width * 0.63,
        size.height * 0.48,
      )
      ..cubicTo(
        size.width * 0.76,
        size.height * 0.16,
        size.width * 0.86,
        size.height * 0.78,
        size.width,
        size.height * 0.38,
      );
    canvas.drawPath(
      route,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..strokeCap = StrokeCap.round,
    );

    for (final metric in route.computeMetrics()) {
      final travel = (progress * 1.18).clamp(0.0, 1.0);
      canvas.drawPath(
        metric.extractPath(0, metric.length * travel),
        Paint()
          ..shader = const LinearGradient(
            colors: [LaunchScreen.gold, LaunchScreen.goldLight],
          ).createShader(Offset.zero & size)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.8
          ..strokeCap = StrokeCap.round,
      );
      final tangent = metric.getTangentForOffset(metric.length * travel);
      if (tangent == null) continue;
      canvas.drawCircle(
        tangent.position,
        7,
        Paint()..color = LaunchScreen.gold.withValues(alpha: 0.18),
      );
      canvas.drawCircle(
        tangent.position,
        3.2,
        Paint()..color = LaunchScreen.goldLight,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RouteProgressPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
