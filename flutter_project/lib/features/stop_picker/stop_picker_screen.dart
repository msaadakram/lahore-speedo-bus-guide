import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/app_palette.dart';
import '../../app/theme/app_tokens.dart';
import '../../core/services/location_service.dart';
import '../../data/models/bus_stop.dart';
import '../../data/repositories/stop_repository.dart';
import '../../shared/widgets/app_icons.dart';
import '../../shared/widgets/app_widgets.dart';

/// StopPickerScreen (Metro module 1073) — replaces the RN `onSelect` callback
/// with a `pop(result)`.
class StopPickerScreen extends ConsumerStatefulWidget {
  const StopPickerScreen({required this.mode, this.title, super.key});

  final String mode;
  final String? title;

  @override
  ConsumerState<StopPickerScreen> createState() => _StopPickerScreenState();
}

class _StopPickerScreenState extends ConsumerState<StopPickerScreen> {
  String _query = '';
  bool _locating = false;

  @override
  void initState() {
    super.initState();
    // Defensive: the index is normally warmed during startup, but make sure
    // the list is populated even on a warm resume.
    StopRepository.instance.ensureLoaded();
  }

  List<BusStop> get _results => StopRepository.instance.search(_query);

  String get _title =>
      widget.title ??
      (widget.mode == 'from'
          ? 'Select Departure Stop'
          : 'Select Destination Stop');

  Future<void> _useCurrentLocation() async {
    setState(() => _locating = true);
    try {
      final position = await ref
          .read(locationServiceProvider)
          .currentLocation();
      if (position == null || !mounted) return;
      final near = StopRepository.instance
          .nearby(latitude: position.latitude, longitude: position.longitude)
          .firstOrNull;
      if (near == null) return;
      final stop = near.stop;
      if (!mounted) return;
      Navigator.of(context).pop(stop);
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPaletteScope.paletteOf(context);
    final insets = MediaQuery.paddingOf(context);
    final results = _results;

    return Scaffold(
      body: ColoredBox(
        color: palette.background,
        child: Column(
          children: [
            // ------------------------------------------------------ header
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: palette.heroGradient,
                boxShadow: palette.softShadow,
              ),
              padding: EdgeInsets.only(
                left: Tokens.spaceMd,
                right: Tokens.spaceMd,
                top: insets.top + Tokens.spaceSm,
                bottom: Tokens.spaceSm,
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      AppPressable(
                        onPressed: () => Navigator.of(context).pop(),
                        borderless: true,
                        rippleColor: Colors.white,
                        child: Container(
                          height: 35,
                          width: 35,
                          alignment: Alignment.center,
                          margin: const EdgeInsets.only(right: Tokens.spaceXs),
                          child: const Icon(
                            AppIcons.arrowLeft,
                            size: 24,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          _title,
                          style: const TextStyle(
                            fontSize: Tokens.fontXl,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: Tokens.spaceMd),
                  TextField(
                    controller: TextEditingController(text: _query),
                    autofocus: true,
                    onChanged: (v) => setState(() => _query = v),
                    cursorColor: Colors.white,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: Tokens.fontBase,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Type stop name...',
                      hintStyle: const TextStyle(
                        color: Color(0xB3FFFFFF),
                        fontSize: Tokens.fontBase,
                      ),
                      filled: true,
                      fillColor: const Color(0x26FFFFFF),
                      prefixIcon: const Icon(
                        AppIcons.magnify,
                        size: 18,
                        color: Color(0xCCFFFFFF),
                      ),
                      prefixIconConstraints: const BoxConstraints(
                        minWidth: 44,
                        minHeight: 44,
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
                ],
              ),
            ),

            // ------------------------------------------------------ list
            Expanded(
              child: ListView.separated(
                key: const Key('stop-picker-list'),
                padding: const EdgeInsets.only(bottom: Tokens.spaceXl),
                itemCount:
                    results.length +
                    (widget.mode == 'from' ? 2 : 1) +
                    (results.isEmpty ? 1 : 0),
                separatorBuilder: (_, _) => const SizedBox.shrink(),
                itemBuilder: (context, i) {
                  var index = i;
                  if (widget.mode == 'from') {
                    if (index == 0) return _buildUseCurrentLocation();
                    index -= 1;
                  }
                  if (index == 0) return _buildCounter(results.length);
                  index -= 1;
                  if (results.isEmpty) return _buildEmpty();
                  return _buildRow(results[index]);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUseCurrentLocation() {
    final palette = AppPaletteScope.paletteOf(context);
    return AppPressable(
      onPressed: _locating ? null : _useCurrentLocation,
      child: Container(
        padding: const EdgeInsets.all(Tokens.spaceMd),
        color: palette.card,
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: palette.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(Tokens.radiusMd),
              ),
              child: Icon(AppIcons.mapMarker, size: 20, color: palette.primary),
            ),
            const SizedBox(width: Tokens.spaceMd),
            Expanded(
              child: Text(
                _locating ? 'Finding your location…' : 'Use current location',
                style: TextStyle(
                  fontSize: Tokens.fontBase,
                  fontWeight: FontWeight.w700,
                  color: palette.primary,
                ),
              ),
            ),
            if (_locating)
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: palette.primary,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCounter(int count) {
    final palette = AppPaletteScope.paletteOf(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Tokens.spaceMd,
        vertical: Tokens.spaceSm,
      ),
      child: Text(
        '$count All Stops',
        style: TextStyle(
          fontSize: Tokens.fontSm,
          fontWeight: FontWeight.w600,
          color: palette.textSecondary,
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    final palette = AppPaletteScope.paletteOf(context);
    return Padding(
      padding: const EdgeInsets.only(top: Tokens.spaceXl),
      child: Center(
        child: Text(
          'No stops found',
          style: TextStyle(color: palette.textSecondary),
        ),
      ),
    );
  }

  Widget _buildRow(BusStop stop) {
    final palette = AppPaletteScope.paletteOf(context);
    final lines = stop.routes.length;
    return AppPressable(
      onPressed: () => Navigator.of(context).pop(stop),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Tokens.spaceMd,
          vertical: Tokens.spaceSm,
        ),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: palette.border)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
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
                      fontWeight: FontWeight.w700,
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
