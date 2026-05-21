import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/colors.dart';
import '../core/strings.dart';
import '../providers/locale_provider.dart';

class FooterWidget extends ConsumerWidget {
  final VoidCallback onProduct;
  final VoidCallback onPricing;
  final VoidCallback onCountries;
  final VoidCallback onContact;

  const FooterWidget({
    super.key,
    required this.onProduct,
    required this.onPricing,
    required this.onCountries,
    required this.onContact,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final wide = MediaQuery.of(context).size.width >= 768;

    return Container(
      color: AppColors.dark,
      width: double.infinity,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 56),
            child: Column(
              children: [
                if (wide)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 2, child: _Brand(locale: locale)),
                      Expanded(child: _LinkColumn(
                        title: S.of(locale, 'footer_product'),
                        links: [
                          (label: S.of(locale, 'footer_product'),   onTap: onProduct),
                          (label: S.of(locale, 'footer_pricing'),   onTap: onPricing),
                          (label: S.of(locale, 'footer_countries'), onTap: onCountries),
                          (label: S.of(locale, 'footer_contact'),   onTap: onContact),
                        ],
                      )),
                      Expanded(child: _LinkColumn(
                        title: locale == 'pt' ? 'Legal' : 'Legal',
                        links: [
                          (label: S.of(locale, 'footer_privacy'), onTap: () {}),
                          (label: S.of(locale, 'footer_terms'),   onTap: () {}),
                        ],
                      )),
                    ],
                  )
                else
                  Column(
                    children: [
                      _Brand(locale: locale),
                      const SizedBox(height: 32),
                      Wrap(
                        spacing: 24,
                        runSpacing: 12,
                        children: [
                          _FooterLink(label: S.of(locale, 'footer_product'),   onTap: onProduct),
                          _FooterLink(label: S.of(locale, 'footer_pricing'),   onTap: onPricing),
                          _FooterLink(label: S.of(locale, 'footer_countries'), onTap: onCountries),
                          _FooterLink(label: S.of(locale, 'footer_contact'),   onTap: onContact),
                          _FooterLink(label: S.of(locale, 'footer_privacy'),   onTap: () {}),
                          _FooterLink(label: S.of(locale, 'footer_terms'),     onTap: () {}),
                        ],
                      ),
                    ],
                  ),
                const SizedBox(height: 48),
                const Divider(color: Colors.white12),
                const SizedBox(height: 24),
                Text(
                  S.of(locale, 'footer_copy'),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: Colors.white30,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Brand extends StatelessWidget {
  final String locale;
  const _Brand({required this.locale});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.amber,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                child: Text('S',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20)),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Serafy',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    )),
                Text('by LILIPTECH',
                    style: GoogleFonts.inter(
                      color: AppColors.blue,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.8,
                    )),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          S.of(locale, 'footer_tagline'),
          style: GoogleFonts.inter(
            color: Colors.white38,
            fontSize: 14,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 20),
        // Social icons placeholder
        Row(
          children: [
            _SocialIcon(icon: Icons.language_rounded),
            const SizedBox(width: 10),
            _SocialIcon(icon: Icons.email_rounded),
            const SizedBox(width: 10),
            _SocialIcon(icon: Icons.business_rounded),
          ],
        ),
      ],
    );
  }
}

class _SocialIcon extends StatefulWidget {
  final IconData icon;
  const _SocialIcon({required this.icon});

  @override
  State<_SocialIcon> createState() => _SocialIconState();
}

class _SocialIconState extends State<_SocialIcon> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: _hovered ? Colors.white12 : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Icon(widget.icon,
            color: _hovered ? AppColors.amber : Colors.white38, size: 18),
      ),
    );
  }
}

class _LinkColumn extends StatelessWidget {
  final String title;
  final List<({String label, VoidCallback onTap})> links;

  const _LinkColumn({required this.title, required this.links});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        ...links.map((l) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _FooterLink(label: l.label, onTap: l.onTap),
            )),
      ],
    );
  }
}

class _FooterLink extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const _FooterLink({required this.label, required this.onTap});

  @override
  State<_FooterLink> createState() => _FooterLinkState();
}

class _FooterLinkState extends State<_FooterLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 150),
          style: GoogleFonts.inter(
            color: _hovered ? AppColors.amber : Colors.white38,
            fontSize: 14,
          ),
          child: Text(widget.label),
        ),
      ),
    );
  }
}
