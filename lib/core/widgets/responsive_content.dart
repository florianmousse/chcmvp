import 'package:flutter/material.dart';

/// Keeps forms and tables readable on wide monitors without changing mobile.
class ResponsiveContent extends StatelessWidget {
  const ResponsiveContent({
    super.key,
    required this.child,
    this.maxWidth = 1040,
  });
  final Widget child;
  final double maxWidth;
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: child,
    ),
  );
}

/// Desktop cards are all visible and mouse-accessible; mobile keeps its carousel.
class DesktopCardGrid extends StatelessWidget {
  const DesktopCardGrid({
    super.key,
    required this.children,
    required this.height,
  });
  final List<Widget> children;
  final double height;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final availableColumns = constraints.maxWidth >= 960
          ? 3
          : constraints.maxWidth >= 720
          ? 2
          : 1;
      final columns = children.isEmpty
          ? 1
          : availableColumns.clamp(1, children.length);
      final width = (constraints.maxWidth - (columns - 1) * 16) / columns;
      return Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          for (final child in children)
            SizedBox(width: width, height: height, child: child),
        ],
      );
    },
  );
}
