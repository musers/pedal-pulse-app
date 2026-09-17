import 'package:flutter/material.dart';

class ResponsiveBreakpoints {
  static const double mobileMax = 600;
  static const double tabletMax = 1024;
}

class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < ResponsiveBreakpoints.mobileMax;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= ResponsiveBreakpoints.mobileMax &&
      MediaQuery.of(context).size.width < ResponsiveBreakpoints.tabletMax;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= ResponsiveBreakpoints.tabletMax;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= ResponsiveBreakpoints.tabletMax && desktop != null) {
          return desktop!;
        }
        if (constraints.maxWidth >= ResponsiveBreakpoints.mobileMax && tablet != null) {
          return tablet!;
        }
        return mobile;
      },
    );
  }
}
