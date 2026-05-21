import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/colors.dart';
import '../core/strings.dart';
import '../providers/locale_provider.dart';
import '../widgets/section_wrapper.dart';

class SectorsSection extends ConsumerWidget {
  const SectorsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final desktop = isDesktop(context);
    final tablet = isTablet(context);

    final sectors = [
      (icon: Icons.account_balance_rounded,   color: const Color(0xFF2563EB), key: 's_banks'),
      (icon: Icons.cell_tower_rounded,         color: const Color(0xFF7C3AED), key: 's_telco'),
      (icon: Icons.bolt_rounded,               color: const Color(0xFFD97706), key: 's_energy'),
      (icon: Icons.shopping_bag_rounded,       color: const Color(0xFF059669), key: 's_retail'),
      (icon: Icons.account_balance_outlined,   color: const Color(0xFF0891B2), key: 's_gov'),
      (icon: Icons.business_center_rounded,    color: const Color(0xFFDC2626), key: 's_sme'),
    ];

    final cols = desktop ? 3 : (tablet ? 2 : 1);

    return SectionWrapper(
      backgroundColor: AppColors.surface,
      child: Column(
        children: [
          _SectionHeader(
            title: S.of(locale, 'sectors_title'),
            subtitle: S.of(locale, 'sectors_subtitle'),
          ),
          const SizedBox(height: 48),
          _ResponsiveGrid(
            columns: cols,
            children: sectors.map((s) {
              final name = S.of(locale, s.key);
              final desc = S.of(locale, '${s.key}_d');
              return _SectorCard(
                icon: s.icon,
                iconColor: s.color,
                name: name,
                description: desc,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _SectorCard extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final String name;
  final String description;

  const _SectorCard({
    required this.icon,
    required this.iconColor,
    required this.name,
    required this.description,
  });

  @override
  State<_SectorCard> createState() => _SectorCardState();
}

class _SectorCardState extends State<_SectorCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _hovered ? widget.iconColor.withOpacity(0.3) : AppColors.border,
          ),
          boxShadow: _hovered
              ? [BoxShadow(color: widget.iconColor.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 8))]
              : [const BoxShadow(color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: widget.iconColor.withOpacity(_hovered ? 0.18 : 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(widget.icon, color: widget.iconColor, size: 26),
            ),
            const SizedBox(height: 18),
            Text(
              widget.name,
              style: GoogleFonts.inter(
                color: AppColors.text,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.description,
              style: GoogleFonts.inter(
                color: AppColors.textMuted,
                fontSize: 14,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final CrossAxisAlignment alignment;

  const _SectionHeader({
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

class _ResponsiveGrid extends StatelessWidget {
  final int columns;
  final List<Widget> children;

  const _ResponsiveGrid({required this.columns, required this.children});

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (int i = 0; i < children.length; i += columns) {
      final rowChildren = children.skip(i).take(columns).toList();
      rows.add(
        IntrinsicHeight(
          child: Row(
            children: [
              for (int j = 0; j < rowChildren.length; j++) ...[
                if (j > 0) const SizedBox(width: 20),
                Expanded(child: rowChildren[j]),
              ],
              for (int k = rowChildren.length; k < columns; k++) ...[
                const SizedBox(width: 20),
                const Expanded(child: SizedBox()),
              ],
            ],
          ),
        ),
      );
      if (i + columns < children.length) rows.add(const SizedBox(height: 20));
    }
    return Column(children: rows);
  }
}
