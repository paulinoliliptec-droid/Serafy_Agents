import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/colors.dart';
import '../core/strings.dart';
import '../providers/locale_provider.dart';
import 'section_wrapper.dart';

class Navbar extends ConsumerStatefulWidget {
  final VoidCallback onProduct;
  final VoidCallback onPricing;
  final VoidCallback onCountries;
  final VoidCallback onContact;

  const Navbar({
    super.key,
    required this.onProduct,
    required this.onPricing,
    required this.onCountries,
    required this.onContact,
  });

  @override
  ConsumerState<Navbar> createState() => _NavbarState();
}

class _NavbarState extends ConsumerState<Navbar> {
  bool _scrolled = false;

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    final mobile = isMobile(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: AppColors.dark,
        boxShadow: _scrolled
            ? [BoxShadow(color: Colors.black38, blurRadius: 16, offset: const Offset(0, 2))]
            : [],
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1200),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: SizedBox(
              height: 68,
              child: Row(
                children: [
                  // Logo
                  _Logo(),
                  const Spacer(),
                  if (mobile)
                    _MobileMenu(
                      locale: locale,
                      onProduct: widget.onProduct,
                      onPricing: widget.onPricing,
                      onCountries: widget.onCountries,
                      onContact: widget.onContact,
                      onToggleLocale: _toggleLocale,
                    )
                  else ...[
                    _NavLink(S.of(locale, 'nav_product'),   onTap: widget.onProduct),
                    _NavLink(S.of(locale, 'nav_pricing'),   onTap: widget.onPricing),
                    _NavLink(S.of(locale, 'nav_countries'), onTap: widget.onCountries),
                    _NavLink(S.of(locale, 'nav_contact'),   onTap: widget.onContact),
                    const SizedBox(width: 16),
                    _LocaleToggle(locale: locale, onToggle: _toggleLocale),
                    const SizedBox(width: 20),
                    _CtaButton(label: S.of(locale, 'nav_cta')),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _toggleLocale() {
    final cur = ref.read(localeProvider);
    ref.read(localeProvider.notifier).state = cur == 'pt' ? 'en' : 'pt';
  }
}

class _Logo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.amber,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: Text('S',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18)),
          ),
        ),
        const SizedBox(width: 10),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Serafy',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                )),
            Text('by LILIPTECH',
                style: GoogleFonts.inter(
                  color: AppColors.blue,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                )),
          ],
        ),
      ],
    );
  }
}

class _NavLink extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const _NavLink(this.label, {required this.onTap});

  @override
  State<_NavLink> createState() => _NavLinkState();
}

class _NavLinkState extends State<_NavLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 150),
            style: GoogleFonts.inter(
              color: _hovered ? AppColors.amber : Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            child: Text(widget.label),
          ),
        ),
      ),
    );
  }
}

class _LocaleToggle extends StatelessWidget {
  final String locale;
  final VoidCallback onToggle;

  const _LocaleToggle({required this.locale, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white24),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _LocaleTab(label: 'PT', active: locale == 'pt'),
            _LocaleTab(label: 'EN', active: locale == 'en'),
          ],
        ),
      ),
    );
  }
}

class _LocaleTab extends StatelessWidget {
  final String label;
  final bool active;

  const _LocaleTab({required this.label, required this.active});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: active ? AppColors.amber : Colors.transparent,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: active ? Colors.white : Colors.white54,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _CtaButton extends StatefulWidget {
  final String label;
  const _CtaButton({required this.label});

  @override
  State<_CtaButton> createState() => _CtaButtonState();
}

class _CtaButtonState extends State<_CtaButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: _hovered ? const Color(0xFFE09610) : AppColors.amber,
            borderRadius: BorderRadius.circular(8),
            boxShadow: _hovered
                ? [BoxShadow(color: AppColors.amber.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))]
                : [],
          ),
          child: Text(
            widget.label,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _MobileMenu extends StatelessWidget {
  final String locale;
  final VoidCallback onProduct, onPricing, onCountries, onContact, onToggleLocale;

  const _MobileMenu({
    required this.locale,
    required this.onProduct,
    required this.onPricing,
    required this.onCountries,
    required this.onContact,
    required this.onToggleLocale,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _LocaleToggle(locale: locale, onToggle: onToggleLocale),
        const SizedBox(width: 8),
        PopupMenuButton<String>(
          icon: const Icon(Icons.menu, color: Colors.white),
          color: AppColors.darkAlt,
          onSelected: (v) {
            switch (v) {
              case 'product':   onProduct();   break;
              case 'pricing':   onPricing();   break;
              case 'countries': onCountries(); break;
              case 'contact':   onContact();   break;
            }
          },
          itemBuilder: (_) => [
            PopupMenuItem(value: 'product',
                child: Text(S.of(locale, 'nav_product'),
                    style: const TextStyle(color: Colors.white))),
            PopupMenuItem(value: 'pricing',
                child: Text(S.of(locale, 'nav_pricing'),
                    style: const TextStyle(color: Colors.white))),
            PopupMenuItem(value: 'countries',
                child: Text(S.of(locale, 'nav_countries'),
                    style: const TextStyle(color: Colors.white))),
            PopupMenuItem(value: 'contact',
                child: Text(S.of(locale, 'nav_contact'),
                    style: const TextStyle(color: Colors.white))),
          ],
        ),
      ],
    );
  }
}
