import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/app_palette.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_tokens.dart';
import '../widgets/app_icons.dart';

/// Recreates React Native's `Pressable` ripple behaviour in Material terms.
class AppPressable extends StatelessWidget {
  const AppPressable({
    required this.onPressed,
    required this.child,
    this.style,
    this.rippleColor,
    this.borderless = true,
    this.disabled = false,
    super.key,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final EdgeInsetsGeometry? style;
  final Color? rippleColor;
  final bool borderless;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final palette = AppPaletteScope.paletteOf(context);
    final enabled = onPressed != null && !disabled;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onPressed : null,
        borderRadius: BorderRadius.circular(Tokens.shapeMd),
        splashColor: (rippleColor ?? palette.primary).withValues(alpha: 0.16),
        highlightColor: (rippleColor ?? palette.primary).withValues(
          alpha: 0.08,
        ),
        child: Padding(padding: style ?? EdgeInsets.zero, child: child),
      ),
    );
  }
}

/// The in-page hero header. It now carries the signature green gradient of the
/// reference artwork, with a soft drop shadow so it sits above the canvas.
class AppPageHeader extends StatelessWidget {
  const AppPageHeader({
    required this.title,
    this.subtitle,
    this.backgroundColor,
    this.onBack,
    this.trailing,
    this.titleStyle,
    this.gradient,
    this.elevated = true,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Color? backgroundColor;
  final VoidCallback? onBack;
  final Widget? trailing;
  final TextStyle? titleStyle;
  final Gradient? gradient;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    final palette = AppPaletteScope.paletteOf(context);
    final insets = MediaQuery.paddingOf(context);
    final g =
        gradient ??
        (backgroundColor != null
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [backgroundColor!, backgroundColor!],
              )
            : palette.heroGradient);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: g,
          boxShadow: elevated ? palette.softShadow : null,
        ),
        padding: EdgeInsets.only(
          left: AppSpacing.screen,
          right: AppSpacing.screen,
          top: insets.top + Tokens.spaceMd,
          bottom: Tokens.spaceMd,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (onBack != null) ...[
              _RoundIconButton(
                icon: AppIcons.arrowLeft,
                onPressed: onBack,
                tooltip: 'Back',
              ),
              const SizedBox(width: Tokens.spaceSm),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style:
                        titleStyle ??
                        const TextStyle(
                          fontSize: Tokens.fontXl,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                          height: 1.2,
                          color: Colors.white,
                        ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        fontSize: Tokens.fontMd,
                        fontWeight: FontWeight.w500,
                        color: Color(0xE6FFFFFF),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: Tokens.spaceSm),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}

/// A soft, translucent circular button for header actions.
class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.onPressed,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return AppPressable(
      onPressed: onPressed,
      borderless: true,
      rippleColor: Colors.white,
      child: Container(
        width: 40,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 22, color: Colors.white),
      ),
    );
  }
}

/// Bordered card — the app's only container style, now with a soft, diffuse,
/// green-tinted shadow like the reference art.
class AppCard extends StatelessWidget {
  const AppCard({
    required this.child,
    this.padding = const EdgeInsets.all(Tokens.spaceMd),
    this.margin,
    this.radius = Tokens.shapeLg,
    this.color,
    this.borderColor,
    this.elevation = 0,
    this.gradient,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final Color? color;
  final Color? borderColor;
  final double elevation;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    final palette = AppPaletteScope.paletteOf(context);
    final bg = color ?? palette.card;
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: gradient == null ? bg : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor ?? palette.border),
        boxShadow: elevation > 0 ? palette.softShadow : null,
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

/// Primary pill button with the soft green gradient.
class AppButton extends StatelessWidget {
  const AppButton({
    required this.label,
    required this.onPressed,
    this.enabled = true,
    this.icon,
    this.muted = false,
    this.expand = true,
    this.gradient,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool enabled;
  final IconData? icon;
  final bool muted;
  final bool expand;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    final palette = AppPaletteScope.paletteOf(context);
    final fg = enabled
        ? (muted ? palette.primary : palette.onPrimary)
        : palette.textSecondary;
    final bg = enabled
        ? (muted ? palette.surfaceTint : palette.primary)
        : palette.surfaceTint;
    final g = enabled && !muted ? (gradient ?? palette.heroGradient) : null;

    final content = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 19, color: fg),
          const SizedBox(width: Tokens.spaceSm),
        ],
        Text(
          label,
          style: TextStyle(
            fontSize: Tokens.fontBase,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.1,
            color: fg,
          ),
        ),
      ],
    );

    return AppPressable(
      onPressed: enabled ? onPressed : null,
      child: Container(
        width: expand ? double.infinity : null,
        padding: const EdgeInsets.symmetric(
          horizontal: Tokens.spaceLg,
          vertical: Tokens.spaceMd,
        ),
        decoration: BoxDecoration(
          color: g == null ? bg : null,
          gradient: g,
          borderRadius: BorderRadius.circular(Tokens.shapePill),
          boxShadow: enabled && !muted ? palette.softShadow : null,
        ),
        child: expand ? Center(child: content) : content,
      ),
    );
  }
}

/// Text-only action button.
class AppTextButton extends StatelessWidget {
  const AppTextButton({
    required this.label,
    required this.onPressed,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final palette = AppPaletteScope.paletteOf(context);
    return AppPressable(
      onPressed: onPressed,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: Tokens.spaceMd,
          horizontal: Tokens.spaceSm,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: Tokens.fontBase,
            fontWeight: FontWeight.w700,
            color: palette.primary,
          ),
        ),
      ),
    );
  }
}

/// Filled button used on the coloured header blocks.
class AppFilledDarkButton extends StatelessWidget {
  const AppFilledDarkButton({
    required this.label,
    required this.onPressed,
    this.background,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color? background;

  @override
  Widget build(BuildContext context) {
    final palette = AppPaletteScope.paletteOf(context);
    return AppPressable(
      onPressed: onPressed,
      rippleColor: Colors.white,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: Tokens.spaceLg,
          vertical: Tokens.spaceMd,
        ),
        decoration: BoxDecoration(
          color: background ?? palette.primary,
          borderRadius: BorderRadius.circular(Tokens.shapePill),
          boxShadow: palette.softShadow,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: Tokens.fontBase,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

/// Uppercase section header.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    required this.text,
    this.margin = EdgeInsets.zero,
    this.color,
    super.key,
  });

  final String text;
  final EdgeInsetsGeometry margin;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final palette = AppPaletteScope.paletteOf(context);
    return Padding(
      padding: margin,
      child: Text(
        text,
        style: TextStyle(
          fontSize: Tokens.fontSm,
          fontWeight: FontWeight.w800,
          color: color ?? palette.textSecondary,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}

/// Centred icon + message used for every empty / permission / error state.
class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.icon,
    required this.message,
    this.action,
    this.tone,
    super.key,
  });

  final IconData icon;
  final String message;
  final Widget? action;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final palette = AppPaletteScope.paletteOf(context);
    final c = tone ?? palette.textSecondary;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Tokens.spaceXl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: palette.surfaceTint,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 34, color: c),
            ),
            const SizedBox(height: Tokens.spaceMd),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: Tokens.fontBase,
                height: 1.4,
                color: palette.textSecondary,
              ),
            ),
            if (action != null) ...[
              const SizedBox(height: Tokens.spaceLg),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Label / value box used on the route detail screen.
class StatBox extends StatelessWidget {
  const StatBox({
    required this.label,
    required this.value,
    this.color,
    this.icon,
    super.key,
  });

  final String label;
  final String value;
  final Color? color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final palette = AppPaletteScope.paletteOf(context);
    final c = color ?? palette.primary;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Tokens.spaceSm,
          vertical: Tokens.spaceMd,
        ),
        decoration: BoxDecoration(
          color: c,
          borderRadius: BorderRadius.circular(Tokens.shapeMd),
          boxShadow: palette.softShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: 13,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                  const SizedBox(width: 4),
                ],
                Flexible(
                  child: Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: Tokens.fontXs,
                      fontWeight: FontWeight.w800,
                      color: Colors.white.withValues(alpha: 0.9),
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: Tokens.fontMd,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
