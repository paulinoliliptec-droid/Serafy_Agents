import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/colors.dart';
import '../core/strings.dart';
import '../providers/locale_provider.dart';
import '../widgets/section_header.dart';
import '../widgets/section_wrapper.dart';

class AgentsSection extends ConsumerWidget {
  const AgentsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final desktop = isDesktop(context);
    final tablet = isTablet(context);

    final agents = [
      (icon: Icons.support_agent_rounded,  color: const Color(0xFF2563EB),
       key: 'a_support',  kiesse: false),
      (icon: Icons.storefront_rounded,      color: const Color(0xFF059669),
       key: 'a_sales',    kiesse: false),
      (icon: Icons.gavel_rounded,           color: const Color(0xFF7C3AED),
       key: 'a_legal',    kiesse: true),
      (icon: Icons.badge_rounded,           color: const Color(0xFF0891B2),
       key: 'a_hr',       kiesse: false),
      (icon: Icons.account_balance_rounded, color: const Color(0xFFD97706),
       key: 'a_finance',  kiesse: false),
      (icon: Icons.campaign_rounded,        color: const Color(0xFFDC2626),
       key: 'a_marketing',kiesse: false),
    ];

    final cols = desktop ? 3 : (tablet ? 2 : 1);

    return SectionWrapper(
      child: Column(
        children: [
          SectionHeader(
            title: S.of(locale, 'agents_title'),
            subtitle: S.of(locale, 'agents_subtitle'),
          ),
          const SizedBox(height: 48),
          ResponsiveGrid(
            columns: cols,
            children: agents.map((a) => _AgentCard(
                  locale: locale,
                  icon: a.icon,
                  iconColor: a.color,
                  nameKey: a.key,
                  descKey: '${a.key}_d',
                  kiesse: a.kiesse,
                )).toList(),
          ),
        ],
      ),
    );
  }
}

class _AgentCard extends StatefulWidget {
  final String locale;
  final IconData icon;
  final Color iconColor;
  final String nameKey;
  final String descKey;
  final bool kiesse;

  const _AgentCard({
    required this.locale,
    required this.icon,
    required this.iconColor,
    required this.nameKey,
    required this.descKey,
    required this.kiesse,
  });

  @override
  State<_AgentCard> createState() => _AgentCardState();
}

class _AgentCardState extends State<_AgentCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final name = S.of(widget.locale, widget.nameKey);
    final desc = S.of(widget.locale, widget.descKey);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: _hovered ? AppColors.dark : AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _hovered ? widget.iconColor.withOpacity(0.5) : AppColors.border,
          ),
          boxShadow: _hovered
              ? [BoxShadow(color: widget.iconColor.withOpacity(0.15), blurRadius: 24, offset: const Offset(0, 10))]
              : [const BoxShadow(color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: widget.iconColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(widget.icon, color: widget.iconColor, size: 26),
                ),
                if (widget.kiesse) ...[
                  const SizedBox(width: 10),
                  _KiesseBadge(locale: widget.locale),
                ],
              ],
            ),
            const SizedBox(height: 18),
            Text(
              name,
              style: GoogleFonts.inter(
                color: _hovered ? Colors.white : AppColors.text,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              desc,
              style: GoogleFonts.inter(
                color: _hovered ? Colors.white60 : AppColors.textMuted,
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

class _KiesseBadge extends StatelessWidget {
  final String locale;
  const _KiesseBadge({required this.locale});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.amber.withOpacity(0.12),
        border: Border.all(color: AppColors.amber.withOpacity(0.4)),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        S.of(locale, 'kiesse_badge'),
        style: GoogleFonts.inter(
          color: AppColors.amber,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
