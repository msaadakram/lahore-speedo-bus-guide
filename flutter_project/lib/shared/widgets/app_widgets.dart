import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/app_palette.dart';
import '../../app/theme/app_spacing.dart';
import '../../app/theme/app_tokens.dart';
import '../widgets/app_icons.dart';

/// Recreates React Native's `Pressable` behaviour with Material ripple, while
/// exposing proper button semantics to accessibility services.
class AppPressable extends StatelessWidget {
  const AppPressable({
    required this.onPressed,
    required this.child,
    this.style,
    this.rippleColor,
    this.borderless = true,
    this.disabled = false,
    this.selected = false,
    this.semanticLabel,
    this.borderRadius,
    super.key,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final EdgeInsetsGeometry? style;
  final Color? rippleColor;
  final bool borderless;
  final bool disabled;
  final bool selected;
  final String? semanticLabel;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final palette = AppPaletteScope.paletteOf(context);
    final enabled = onPressed != null && !disabled;
    final radius = borderRadius ?? BorderRadius.circular(Tokens.shapeMd);

    return Semantics(
      enabled: enabled,
      button: true,
      selected: selected,
      label: semanticLabel,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onPressed : null,
          customBorder: RoundedRectangleBorder(borderRadius: radius),
          splashColor: (rippleColor ?? palette.primary).withValues(alpha: .14),
          highlightColor: (rippleColor ?? palette.primary).withValues(
            alpha: .08,
          ),
          child: Padding(padding: style ?? EdgeInsets.zero, child: child),
        ),
      ),
    );
  }
}

/// The shared canvas used behind every screen. It keeps the tab surfaces tied
/// to the same soft vertical gradient instead of a flat scaffold colour.
class AppCanvas extends StatelessWidget {
  const AppCanvas({required this.child, this.safeArea = false, super.key});

  final Widget child;
  final bool safeArea;

  @override
  Widget build(BuildContext context) {
    final palette = AppPaletteScope.paletteOf(context);
    final content = DecoratedBox(
      decoration: BoxDecoration(gradient: palette.canvasGradient),
      child: child,
    );
    return safeArea ? SafeArea(child: content) : content;
  }
}

/// A translucent circular action button for coloured hero headers.
class AppGlassButton extends StatelessWidget {
  const AppGlassButton({
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.size = 42,
    this.iconSize = 22,
    super.key,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final button = AppPressable(
      onPressed: onPressed,
      borderless: true,
      rippleColor: Colors.white,
      borderRadius: BorderRadius.circular(size / 2),
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: enabled ? .20 : .12),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: .18)),
        ),
        child: Icon(
          icon,
          size: iconSize,
          color: Colors.white.withValues(alpha: enabled ? 1 : .58),
        ),
      ),
    );

    if (tooltip == null) return button;
    return Tooltip(message: tooltip!, child: button);
  }
}

/// The in-page hero header used by every screen.
///
/// The curved bottom edge and diffuse green shadow turn the recovered flat
/// header into a modern, branded surface while keeping the original copy and
/// hidden native app-bar pattern.
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
    this.bottom,
    this.bottomRadius = Tokens.shapeLg,
    this.padding,
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
  final Widget? bottom;
  final double bottomRadius;
  final EdgeInsetsGeometry? padding;

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
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(bottomRadius),
          ),
          boxShadow: elevated ? palette.softShadow : null,
        ),
        padding:
            padding ??
            EdgeInsets.only(
              left: AppSpacing.screen,
              right: AppSpacing.screen,
              top: insets.top + Tokens.spaceMd,
              bottom: bottom == null ? Tokens.spaceLg : Tokens.spaceMd,
            ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (onBack != null) ...[
                  AppGlassButton(
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
                              fontSize: Tokens.fontXxl,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.6,
                              height: 1.15,
                              color: Colors.white,
                            ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          subtitle!,
                          style: const TextStyle(
                            fontSize: Tokens.fontMd,
                            fontWeight: FontWeight.w600,
                            height: 1.35,
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
            if (bottom != null) ...[
              const SizedBox(height: Tokens.spaceMd),
              bottom!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Bordered card with the app's soft green elevation language.
class AppCard extends StatelessWidget {
  const AppCard({
    required this.child,
    this.padding = const EdgeInsets.all(Tokens.spaceMd),
    this.margin,
    this.radius = Tokens.shapeLg,
    this.color,
    this.borderColor,
    this.elevated = false,
    this.gradient,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double radius;
  final Color? color;
  final Color? borderColor;
  final bool elevated;
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
        border: Border.all(
          color: borderColor ?? palette.border.withValues(alpha: .92),
        ),
        boxShadow: elevated ? palette.softShadow : null,
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

/// Primary pill button with the signature green gradient.
class AppButton extends StatelessWidget {
  const AppButton({
    required this.label,
    required this.onPressed,
    this.enabled = true,
    this.icon,
    this.muted = false,
    this.expand = true,
    this.gradient,
    this.loading = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool enabled;
  final IconData? icon;
  final bool muted;
  final bool expand;
  final Gradient? gradient;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final palette = AppPaletteScope.paletteOf(context);
    final active = enabled && !loading;
    final fg = active
        ? (muted ? palette.primary : palette.onPrimary)
        : palette.textSecondary.withValues(alpha: .74);
    final bg = active
        ? (muted ? palette.surfaceTint : palette.primary)
        : palette.background.withValues(alpha: .74);
    final g = active && !muted ? (gradient ?? palette.heroGradient) : null;
    final borderColor = active
        ? (muted ? palette.primary.withValues(alpha: .30) : palette.primary)
        : palette.border;

    final content = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (loading) ...[
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(fg),
            ),
          ),
          const SizedBox(width: Tokens.spaceSm),
        ] else if (icon != null) ...[
          Icon(icon, size: 19, color: fg),
          const SizedBox(width: Tokens.spaceSm),
        ],
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: Tokens.fontBase,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.1,
              color: fg,
            ),
          ),
        ),
      ],
    );

    return AppPressable(
      onPressed: active ? onPressed : null,
      borderRadius: BorderRadius.circular(Tokens.shapePill),
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
          border: Border.all(color: borderColor),
          boxShadow: active && !muted ? palette.softShadow : null,
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
      borderRadius: BorderRadius.circular(Tokens.shapePill),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: Tokens.spaceMd,
          horizontal: Tokens.spaceSm,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: Tokens.fontBase,
            fontWeight: FontWeight.w800,
            color: onPressed == null ? palette.textSecondary : palette.primary,
          ),
        ),
      ),
    );
  }
}

/// Filled button used on coloured surfaces.
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
    return AppButton(
      label: label,
      onPressed: onPressed,
      gradient: background == null
          ? null
          : LinearGradient(colors: [background!, background!]),
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
    this.title,
    this.action,
    this.tone,
    super.key,
  });

  final IconData icon;
  final String message;
  final String? title;
  final Widget? action;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    final palette = AppPaletteScope.paletteOf(context);
    final c = tone ?? palette.primary;
    final content = Padding(
      padding: const EdgeInsets.all(Tokens.spaceXl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 82,
            height: 82,
            decoration: BoxDecoration(
              color: c.withValues(alpha: .12),
              shape: BoxShape.circle,
              border: Border.all(color: c.withValues(alpha: .20)),
            ),
            child: Icon(icon, size: 36, color: c),
          ),
          if (title != null) ...[
            const SizedBox(height: Tokens.spaceMd),
            Text(
              title!,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: Tokens.fontLg,
                fontWeight: FontWeight.w800,
                color: palette.text,
              ),
            ),
          ],
          const SizedBox(height: Tokens.spaceSm),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: Tokens.fontMd,
              height: 1.45,
              color: palette.textSecondary,
            ),
          ),
          if (action != null) ...[
            const SizedBox(height: Tokens.spaceLg),
            action!,
          ],
        ],
      ),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        // In short slots (landscape, very large text), make the state
        // scrollable instead of allowing a RenderFlex overflow.
        if (!constraints.hasBoundedHeight) {
          return Center(child: content);
        }
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(child: content),
          ),
        );
      },
    );
  }
}

/// Label / value box used on route and journey detail screens.
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
                    color: Colors.white.withValues(alpha: .9),
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
                      color: Colors.white.withValues(alpha: .9),
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
