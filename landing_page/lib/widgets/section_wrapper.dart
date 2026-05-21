import 'package:flutter/material.dart';

class SectionWrapper extends StatelessWidget {
  final Widget child;
  final Color? backgroundColor;
  final double verticalPadding;
  final double maxWidth;

  const SectionWrapper({
    super.key,
    required this.child,
    this.backgroundColor,
    this.verticalPadding = 80,
    this.maxWidth = 1200,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: backgroundColor,
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: verticalPadding, horizontal: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: child,
        ),
      ),
    );
  }
}

bool isDesktop(BuildContext context) =>
    MediaQuery.of(context).size.width >= 1024;

bool isTablet(BuildContext context) {
  final w = MediaQuery.of(context).size.width;
  return w >= 640 && w < 1024;
}

bool isMobile(BuildContext context) =>
    MediaQuery.of(context).size.width < 640;
