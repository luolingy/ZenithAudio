import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

enum ScreenSize { mobile, tablet, desktop }

ScreenSize getScreenSize(BuildContext context) {
  final width = MediaQuery.of(context).size.width;
  if (width < AppConstants.mobileBreakpoint) return ScreenSize.mobile;
  if (width < AppConstants.tabletBreakpoint) return ScreenSize.tablet;
  return ScreenSize.desktop;
}

bool isMobile(BuildContext context) =>
    MediaQuery.of(context).size.width < AppConstants.mobileBreakpoint;

bool isTablet(BuildContext context) {
  final width = MediaQuery.of(context).size.width;
  return width >= AppConstants.mobileBreakpoint &&
      width < AppConstants.tabletBreakpoint;
}

bool isDesktop(BuildContext context) =>
    MediaQuery.of(context).size.width >= AppConstants.tabletBreakpoint;
