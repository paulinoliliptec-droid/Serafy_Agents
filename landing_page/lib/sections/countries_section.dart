import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/colors.dart';
import '../core/strings.dart';
import '../providers/locale_provider.dart';
import '../widgets/section_header.dart';
import '../widgets/section_wrapper.dart';

class CountriesSection extends ConsumerWidget {
  const CountriesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final desktop = isDesktop(context);
    final mobile = isMobile(context);

    return SectionWrapper(
      child: Column(
        children: [
          SectionHeader(
            title: S.of(locale, 'countries_title'),
            subtitle: S.of(locale, 'countries_subtitle'),
          ),
          const SizedBox(height: 56),
          Wrap(
            spacing: 20,
            runSpacing: 20,
            alignment: WrapAlignment.center,
            children: kCplpLanding.map((c) => _CountryCard(
                  flag: c.flag,
                  name: locale == 'en' ? c.nameEn : c.namePt,
                  available: S.of(locale, 'countries_available'),
                  mobile: mobile,
                )).toList(),
          ),
        ],
      ),
    );
  }
}

class _CountryCard extends StatefulWidget {
  final String flag;
  final String name;
  final String available;
  final bool mobile;

  const _CountryCard({
    required this.flag,
    required this.name,
    required this.available,
    required this.mobile,
  });

  @override
  State<_CountryCard> createState() => _CountryCardState();
}

class _CountryCardState extends State<_CountryCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: widget.mobile ? double.infinity : 155,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        decoration: BoxDecoration(
          color: _hovered ? AppColors.dark : AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _hovered ? AppColors.blue.withOpacity(0.4) : AppColors.border,
          ),
          boxShadow: _hovered
              ? [BoxShadow(color: AppColors.blue.withOpacity(0.12), blurRadius: 20, offset: const Offset(0, 8))]
              : [const BoxShadow(color: Color(0x08000000), blurRadius: 6, offset: Offset(0, 2))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.flag,
              style: const TextStyle(fontSize: 44),
            ),
            const SizedBox(height: 12),
            Text(
              widget.name,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: _hovered ? Colors.white : AppColors.text,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    widget.available,
                    style: GoogleFonts.inter(
                      color: Colors.green,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
