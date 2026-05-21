import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/colors.dart';
import '../core/strings.dart';
import '../providers/locale_provider.dart';
import '../widgets/section_wrapper.dart';

class SocialProofSection extends ConsumerWidget {
  const SocialProofSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final desktop = isDesktop(context);

    // Placeholder industry logos (text-based)
    final logos = [
      (label: 'BancoAO', icon: Icons.account_balance_rounded),
      (label: 'TelecomPT', icon: Icons.cell_tower_rounded),
      (label: 'OilMZ', icon: Icons.bolt_rounded),
      (label: 'RetailBR', icon: Icons.shopping_bag_rounded),
      (label: 'GovCV', icon: Icons.gavel_rounded),
      (label: 'PME Angola', icon: Icons.business_rounded),
    ];

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0F2040), Color(0xFF0A1628)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 24,
              vertical: desktop ? 80 : 56,
            ),
            child: Column(
              children: [
                Text(
                  S.of(locale, 'social_title'),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: desktop ? 36 : 26,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  S.of(locale, 'social_subtitle'),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: Colors.white60,
                    fontSize: desktop ? 17 : 15,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  S.of(locale, 'social_sectors'),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: AppColors.amber.withOpacity(0.8),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 56),
                // Stat counters
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 48,
                  runSpacing: 32,
                  children: [
                    _StatCounter(value: '50+', label: locale == 'pt' ? 'Empresas' : 'Companies'),
                    _StatCounter(value: '7', label: locale == 'pt' ? 'Países CPLP' : 'CPLP Countries'),
                    _StatCounter(value: '99.9%', label: locale == 'pt' ? 'Uptime' : 'Uptime'),
                    _StatCounter(value: '24/7', label: locale == 'pt' ? 'Disponibilidade' : 'Availability'),
                  ],
                ),
                const SizedBox(height: 56),
                // Placeholder logos
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 16,
                  runSpacing: 16,
                  children: logos.map((l) => _PlaceholderLogo(
                    label: l.label,
                    icon: l.icon,
                  )).toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatCounter extends StatelessWidget {
  final String value;
  final String label;

  const _StatCounter({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            color: AppColors.amber,
            fontSize: 44,
            fontWeight: FontWeight.w800,
            height: 1,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: GoogleFonts.inter(
            color: Colors.white54,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _PlaceholderLogo extends StatefulWidget {
  final String label;
  final IconData icon;

  const _PlaceholderLogo({required this.label, required this.icon});

  @override
  State<_PlaceholderLogo> createState() => _PlaceholderLogoState();
}

class _PlaceholderLogoState extends State<_PlaceholderLogo> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: _hovered ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(widget.icon, color: Colors.white38, size: 18),
            const SizedBox(width: 10),
            Text(
              widget.label,
              style: GoogleFonts.inter(
                color: Colors.white38,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
