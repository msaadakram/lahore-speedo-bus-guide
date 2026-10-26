import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_palette.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_tokens.dart';
import '../../core/services/location_service.dart';
import '../../data/models/bus_stop.dart';
import '../../data/repositories/stop_repository.dart';
import '../../shared/widgets/app_icons.dart';
import '../../shared/widgets/app_widgets.dart';

/// StopPickerScreen — searchable stop selector that returns the chosen stop.
class StopPickerScreen extends ConsumerStatefulWidget {
  const StopPickerScreen({required this.mode, this.title, super.key});

  final String mode;
  final String? title;

  @override
  ConsumerState<StopPickerScreen> createState() => _StopPickerScreenState();
}

class _StopPickerScreenState extends ConsumerState<StopPickerScreen> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';
  bool _locating = false;
  bool _indexLoading = !StopRepository.instance.isLoaded;
  bool _indexFailed = false;

  @override
  void initState() {
    super.initState();
    // Defensive: the launch gate normally warms this index. The picker is also
    // self-sufficient, and it rebuilds once its own load completes.
    unawaited(_prepareIndex());
  }

  Future<void> _prepareIndex() async {
    if (StopRepository.instance.isLoaded) {
      if (mounted) {
        setState(() {
          _indexLoading = false;
          _indexFailed = false;
        });
      }
      return;
    }

    if (mounted) setState(() => _indexLoading = true);
    try {
      await StopRepository.instance.ensureLoaded();
      if (mounted) {
        setState(() {
          _indexLoading = false;
          _indexFailed = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _indexLoading = false;
          _indexFailed = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<BusStop> get _results => StopRepository.instance.search(_query);

  String get _title =>
      widget.title ??
      (widget.mode == 'from'
          ? 'Select Departure Stop'
          : 'Select Destination Stop');

  Future<void> _useCurrentLocation() async {
    if (_locating) return;
    setState(() => _locating = true);
    try {
      final position = await ref
          .read(locationServiceProvider)
          .currentLocation();
      if (!mounted) return;
      if (position == null) {
        _showMessage('Could not determine your location.');
        return;
      }
      final near = StopRepository.instance
          .nearby(latitude: position.latitude, longitude: position.longitude)
          .firstOrNull;
      if (near == null) {
        _showMessage('No stop is close to your current location.');
        return;
      }
      Navigator.of(context).pop(near.stop);
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPaletteScope.paletteOf(context);
    final results = _results;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppCanvas(
        child: Column(
          children: [
            AppPageHeader(
              title: _title,
              onBack: () => Navigator.of(context).pop(),
              bottomRadius: 36,
              bottom: TextField(
                controller: _controller,
                autofocus: true,
                onChanged: (value) => setState(() => _query = value),
                cursorColor: Colors.white,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: Tokens.fontBase,
                  fontWeight: FontWeight.w600,
                ),
                decoration: InputDecoration(
                  hintText: 'Type stop name...',
                  hintStyle: const TextStyle(
                    color: Color(0xB3FFFFFF),
                    fontSize: Tokens.fontBase,
                  ),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: .16),
                  prefixIcon: const Icon(
                    AppIcons.magnify,
                    size: 19,
                    color: Color(0xCCFFFFFF),
                  ),
                  prefixIconConstraints: const BoxConstraints(
                    minWidth: 44,
                    minHeight: 44,
                  ),
                  suffixIcon: _query.isEmpty
                      ? null
                      : Tooltip(
                          message: 'Clear search',
                          child: AppPressable(
                            onPressed: () {
                              _controller.clear();
                              setState(() => _query = '');
                            },
                            borderless: true,
                            rippleColor: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            child: const Icon(
                              AppIcons.close,
                              size: 17,
                              color: Color(0xCCFFFFFF),
                            ),
                          ),
                        ),
                  suffixIconConstraints: const BoxConstraints(
                    minWidth: 42,
                    minHeight: 42,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(Tokens.shapeMd),
                    borderSide: const BorderSide(color: Color(0x40FFFFFF)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(Tokens.shapeMd),
                    borderSide: const BorderSide(color: Color(0x40FFFFFF)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(Tokens.shapeMd),
                    borderSide: const BorderSide(
                      color: Color(0x99FFFFFF),
                      width: 2,
                    ),
                  ),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: Tokens.spaceSm,
                    vertical: 14,
                  ),
                ),
              ),
            ),
            Expanded(
              child: _indexLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _indexFailed
                  ? EmptyState(
                      icon: AppIcons.alertTriangle,
                      title: 'Stop index unavailable',
                      message: 'The bundled stop list could not be loaded on this device.',
                      action: AppButton(
                        label: 'Retry',
                        icon: AppIcons.reload,
                        expand: false,
                        onPressed: _prepareIndex,
                      ),
                    )
                  : ListView.separated(
                      key: const Key('stop-picker-list'),
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.screen,
                        Tokens.spaceMd,
                        AppSpacing.screen,
                        Tokens.spaceXl,
                      ),
                      itemCount:
                          results.length +
                          (widget.mode == 'from' ? 2 : 1) +
                          (results.isEmpty && _query.isNotEmpty ? 1 : 0),
                      separatorBuilder: (_, _) =>
                          const SizedBox(height: Tokens.spaceSm),
                      itemBuilder: (context, index) {
                        var i = index;
                        if (widget.mode == 'from') {
                          if (i == 0) {
                            return _CurrentLocationCard(
                              onTap: _useCurrentLocation,
                              locating: _locating,
                            );
                          }
                          i--;
                        }
                        if (i == 0) {
                          return Text(
                            _query.isEmpty
                                ? '${results.length} All Stops'
                                : '${results.length} matching stop${results.length == 1 ? '' : 's'}',
                            style: TextStyle(
                              fontSize: Tokens.fontSm,
                              fontWeight: FontWeight.w700,
                              color: palette.textSecondary,
                            ),
                          );
                        }
                        i--;
                        if (results.isEmpty) {
                          return const EmptyState(
                            icon: AppIcons.magnify,
                            title: 'No stops found',
                            message: 'Try a shorter search term or another stop name.',
                          );
                        }
                        return _StopRow(stop: results[i]);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CurrentLocationCard extends StatelessWidget {
  const _CurrentLocationCard({required this.onTap, required this.locating});

  final VoidCallback onTap;
  final bool locating;

  @override
  Widget build(BuildContext context) {
    final palette = AppPaletteScope.paletteOf(context);
    return AppCard(
      radius: Tokens.shapeXl,
      gradient: palette.heroGradient,
      child: AppPressable(
        onPressed: locating ? null : onTap,
        borderRadius: BorderRadius.circular(Tokens.shapeXl),
        child: Row(
          children: [
            const Icon(AppIcons.mapMarker, size: 24, color: Colors.white),
            const SizedBox(width: Tokens.spaceMd),
            Expanded(
              child: Text(
                locating ? 'Finding your location…' : 'Use current location',
                style: const TextStyle(
                  fontSize: Tokens.fontBase,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
            if (locating)
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            else
              const Icon(AppIcons.chevronRight, size: 20, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

class _StopRow extends StatelessWidget {
  const _StopRow({required this.stop});

  final BusStop stop;

  @override
  Widget build(BuildContext context) {
    final palette = AppPaletteScope.paletteOf(context);
    final lines = stop.routes.length;
    return AppCard(
      radius: Tokens.shapeXl,
      child: AppPressable(
        onPressed: () => Navigator.of(context).pop(stop),
        borderRadius: BorderRadius.circular(Tokens.shapeLg),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: palette.heroGradient,
                borderRadius: BorderRadius.circular(Tokens.shapeMd),
                boxShadow: palette.softShadow,
              ),
              child: const Icon(AppIcons.stop, size: 22, color: Colors.white),
            ),
            const SizedBox(width: Tokens.spaceMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stop.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: Tokens.fontBase,
                      fontWeight: FontWeight.w800,
                      color: palette.text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$lines ${lines == 1 ? 'line' : 'lines'}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: Tokens.fontSm,
                      color: palette.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(AppIcons.chevronRight, size: 20, color: palette.textSecondary),
          ],
        ),
      ),
    );
  }
}
