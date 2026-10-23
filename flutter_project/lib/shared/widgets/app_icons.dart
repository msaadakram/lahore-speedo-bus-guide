import 'package:flutter/material.dart';

import 'app_icon_data.dart';

/// Icon facade for the whole app.
///
/// Every entry maps one of the `react-native-vector-icons` names recovered from
/// the original APK onto the exact glyph from the bundled
/// `MaterialCommunityIcons` font (see `app_icon_data.dart` for the codepoints).
abstract final class AppIcons {
  const AppIcons._();

  // Navigation / controls
  static const IconData arrowLeft = AppIconData.arrowLeft;
  static const IconData arrowRight = AppIconData.arrowRight;
  static const IconData arrowUp = AppIconData.arrowUp;
  static const IconData chevronDown = AppIconData.chevronDown;
  static const IconData chevronLeft = AppIconData.chevronLeft;
  static const IconData chevronRight = AppIconData.chevronRight;
  static const IconData close = AppIconData.close;

  // Transport
  static const IconData bus = AppIconData.bus;
  static const IconData busSide = AppIconData.busSide;
  static const IconData busMultiple = AppIconData.busMultiple;
  static const IconData map = AppIconData.map;
  static const IconData mapMarker = AppIconData.mapMarker;
  static const IconData mapMarkerAlt = AppIconData.mapMarkerAlt;
  static const IconData mapMarkerOutline = AppIconData.mapMarkerOutline;
  static const IconData flag = AppIconData.flag;
  static const IconData routes = AppIconData.routes;
  static const IconData directions = AppIconData.directions;
  static const IconData directionsWalk = AppIconData.directionsWalk;
  static const IconData walk = AppIconData.walk;
  static const IconData stop = AppIconData.stop;

  // Status / info
  static const IconData clock = AppIconData.clock;
  static const IconData clockFilled = AppIconData.clockFilled;
  static const IconData clockAlt = AppIconData.clock;
  static const IconData timeOutline = AppIconData.timeOutline;
  static const IconData reload = AppIconData.reload;
  static const IconData loop = AppIconData.loop;
  static const IconData magnify = AppIconData.magnify;
  static const IconData search = AppIconData.search;
  static const IconData filter = AppIconData.filter;
  static const IconData information = AppIconData.information;
  static const IconData textOutline = AppIconData.textOutline;
  static const IconData warning = AppIconData.warning;
  static const IconData alertTriangle = AppIconData.warning;
  static const IconData wifiOff = AppIconData.wifiOff;
  static const IconData check = AppIconData.check;
  static const IconData tick = AppIconData.check;
  static const IconData pageFirst = AppIconData.pageFirst;
  static const IconData pageLast = AppIconData.pageLast;
  static const IconData send = AppIconData.send;
  static const IconData share = AppIconData.share;
  static const IconData swapHorizontal = AppIconData.swapHorizontal;
  static const IconData swapVertical = AppIconData.swapVertical;

  // Bottom navigation
  static const IconData homeOutline = AppIconData.homeOutline;
  static const IconData home = AppIconData.home;
  static const IconData cogOutline = AppIconData.cogOutline;
  static const IconData cog = AppIconData.cog;

  // Settings / misc
  static const IconData themeLightDark = AppIconData.themeLightDark;
  static const IconData shield = AppIconData.shield;
  static const IconData link = AppIconData.link;
  static const IconData mail = AppIconData.mail;
  static const IconData web = AppIconData.web;
  static const IconData codeTags = AppIconData.codeTags;
  static const IconData fitScreen = AppIconData.fitScreen;
  static const IconData calendar = AppIconData.calendar;
  static const IconData qrCode = AppIconData.qrCode;

  /// Resolve a MaterialCommunityIcons name to the exact glyph. Unknown names
  /// fall back to `information` so the UI never crashes.
  static IconData byName(String name) {
    final data = AppIconData.byName(name);
    return data ?? AppIconData.information;
  }
}
