import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/colors.dart';
import '../core/strings.dart';
import '../providers/locale_provider.dart';
import '../widgets/section_wrapper.dart';

class HeroSection extends ConsumerWidget {
  const HeroSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final desktop = isDesktop(context);
    final mobile = isMobile(context);

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(gradient: AppColors.heroGradient),
      child: Stack(
        children: [
          // Subtle grid overlay
          Positioned.fill(child: CustomPaint(painter: _GridPainter())),
          // Glow orbs
          Positioned(
            top: -80,
            right: -60,
            child: _GlowOrb(color: AppColors.amber.withOpacity(0.12), size: 400),
          ),
          Positioned(
            bottom: -40,
            left: -80,
            child: _GlowOrb(color: AppColors.blue.withOpacity(0.1), size: 300),
          ),
          // Content
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: desktop ? 120 : mobile ? 72 : 96,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Top badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.amber.withOpacity(0.12),
                        border: Border.all(color: AppColors.amber.withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: AppColors.amber,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            S.of(locale, 'hero_countries_label'),
                            style: GoogleFonts.inter(
                              color: AppColors.amber,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Title
                    Text(
                      S.of(locale, 'hero_title'),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: desktop ? 58 : mobile ? 36 : 46,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                        letterSpacing: -1.2,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Subtitle
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 640),
                      child: Text(
                        S.of(locale, 'hero_subtitle'),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          color: Colors.white60,
                          fontSize: desktop ? 18 : 15,
                          height: 1.7,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    // CTAs
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 14,
                      runSpacing: 12,
                      children: [
                        _HeroCta(
                          label: S.of(locale, 'hero_cta_primary'),
                          primary: true,
                        ),
                        _HeroCta(
                          label: S.of(locale, 'hero_cta_secondary'),
                          primary: false,
                        ),
                      ],
                    ),
                    const SizedBox(height: 64),
                    // Country flags
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 24,
                      runSpacing: 16,
                      children: kCplpLanding.map((c) => _CountryPill(
                            flag: c.flag,
                            name: locale == 'en' ? c.nameEn : c.namePt,
                          )).toList(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroCta extends StatefulWidget {
  final String label;
  final bool primary;

  const _HeroCta({required this.label, required this.primary});

  @override
  State<_HeroCta> createState() => _HeroCtaState();
}

class _HeroCtaState extends State<_HeroCta> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final mobile = isMobile(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: EdgeInsets.symmetric(
            horizontal: mobile ? 28 : 32,
            vertical: 16,
          ),
          decoration: BoxDecoration(
            color: widget.primary
                ? (_hovered ? const Color(0xFFE09610) : AppColors.amber)
                : Colors.transparent,
            border: widget.primary
                ? null
                : Border.all(color: _hovered ? Colors.white : Colors.white38, width: 1.5),
            borderRadius: BorderRadius.circular(10),
            boxShadow: widget.primary && _hovered
                ? [BoxShadow(color: AppColors.amber.withOpacity(0.45), blurRadius: 20, offset: const Offset(0, 6))]
                : [],
          ),
          child: Text(
            widget.label,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _CountryPill extends StatelessWidget {
  final String flag;
  final String name;

  const _CountryPill({required this.flag, required this.name});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(flag, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 6),
        Text(
          name,
          style: GoogleFonts.inter(
            color: Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final Color color;
  final double size;
  const _GlowOrb({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, Colors.transparent],
        ),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..strokeWidth = 1;
    const step = 60.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}
