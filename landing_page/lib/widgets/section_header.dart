import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/colors.dart';
import 'section_wrapper.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final CrossAxisAlignment alignment;

  const SectionHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.alignment = CrossAxisAlignment.center,
  });

  @override
  Widget build(BuildContext context) {
    final desktop = isDesktop(context);
    return Column(
      crossAxisAlignment: alignment,
      children: [
        Text(
          title,
          textAlign: alignment == CrossAxisAlignment.center
              ? TextAlign.center
              : TextAlign.start,
          style: GoogleFonts.inter(
            color: AppColors.text,
            fontSize: desktop ? 40 : 30,
            fontWeight: FontWeight.w800,
            height: 1.2,
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: 14),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 580),
          child: Text(
            subtitle,
            textAlign: alignment == CrossAxisAlignment.center
                ? TextAlign.center
                : TextAlign.start,
            style: GoogleFonts.inter(
              color: AppColors.textMuted,
              fontSize: desktop ? 17 : 15,
              height: 1.65,
            ),
          ),
        ),
      ],
    );
  }
}

class ResponsiveGrid extends StatelessWidget {
  final int columns;
  final List<Widget> children;
  final double spacing;

  const ResponsiveGrid({
    super.key,
    required this.columns,
    required this.children,
    this.spacing = 20,
  });

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (int i = 0; i < children.length; i += columns) {
      final rowChildren = children.skip(i).take(columns).toList();
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (int j = 0; j < rowChildren.length; j++) ...[
                if (j > 0) SizedBox(width: spacing),
                Expanded(child: rowChildren[j]),
              ],
              for (int k = rowChildren.length; k < columns; k++) ...[
                SizedBox(width: spacing),
                const Expanded(child: SizedBox()),
              ],
            ],
          ),
        ),
      );
      if (i + columns < children.length) SizedBox(height: spacing);
      rows.add(SizedBox(height: spacing));
    }
    if (rows.isNotEmpty) rows.removeLast();
    return Column(children: rows);
  }
}
