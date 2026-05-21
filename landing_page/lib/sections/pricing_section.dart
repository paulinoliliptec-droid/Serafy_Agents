import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/colors.dart';
import '../core/strings.dart';
import '../providers/locale_provider.dart';
import '../widgets/section_header.dart';
import '../widgets/section_wrapper.dart';

class PricingSection extends ConsumerWidget {
  const PricingSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final desktop = isDesktop(context);
    final mobile = isMobile(context);

    final plans = [
      _Plan(
        nameKey: 'plan_starter',
        price: '\$49',
        popular: false,
        features: [
          (label: '3 ${S.of(locale, 'feat_agents')}',     included: true),
          (label: '2.000 ${S.of(locale, 'feat_convs')}',  included: true),
          (label: S.of(locale, 'feat_channels'),           included: true),
          (label: S.of(locale, 'feat_analytics'),          included: true),
          (label: S.of(locale, 'feat_support_email'),      included: true),
          (label: S.of(locale, 'feat_analytics_adv'),      included: false),
          (label: S.of(locale, 'feat_custom_agents'),      included: false),
          (label: S.of(locale, 'feat_sla'),                included: false),
        ],
      ),
      _Plan(
        nameKey: 'plan_growth',
        price: '\$149',
        popular: true,
        features: [
          (label: '6 ${S.of(locale, 'feat_agents')}',     included: true),
          (label: '10.000 ${S.of(locale, 'feat_convs')}', included: true),
          (label: S.of(locale, 'feat_channels'),           included: true),
          (label: S.of(locale, 'feat_analytics_adv'),      included: true),
          (label: S.of(locale, 'feat_support_prio'),       included: true),
          (label: S.of(locale, 'feat_custom_agents'),      included: true),
          (label: S.of(locale, 'feat_sla'),                included: false),
          (label: S.of(locale, 'feat_on_premise'),         included: false),
        ],
      ),
      _Plan(
        nameKey: 'plan_scale',
        price: '\$399',
        popular: false,
        features: [
          (label: '6 ${S.of(locale, 'feat_agents')}',      included: true),
          (label: '50.000 ${S.of(locale, 'feat_convs')}',  included: true),
          (label: S.of(locale, 'feat_channels'),            included: true),
          (label: S.of(locale, 'feat_analytics_adv'),       included: true),
          (label: S.of(locale, 'feat_support_ded'),         included: true),
          (label: S.of(locale, 'feat_custom_agents'),       included: true),
          (label: S.of(locale, 'feat_sla'),                 included: true),
          (label: S.of(locale, 'feat_on_premise'),          included: false),
        ],
      ),
      _Plan(
        nameKey: 'plan_enterprise',
        price: null,
        popular: false,
        features: [
          (label: locale == 'pt' ? 'Agentes ilimitados' : 'Unlimited agents', included: true),
          (label: locale == 'pt' ? 'Volume personalizado' : 'Custom volume',  included: true),
          (label: S.of(locale, 'feat_channels'),             included: true),
          (label: S.of(locale, 'feat_analytics_adv'),        included: true),
          (label: S.of(locale, 'feat_support_ded'),          included: true),
          (label: S.of(locale, 'feat_custom_agents'),        included: true),
          (label: S.of(locale, 'feat_sla'),                  included: true),
          (label: S.of(locale, 'feat_on_premise'),           included: true),
        ],
      ),
    ];

    return SectionWrapper(
      backgroundColor: AppColors.surface,
      child: Column(
        children: [
          SectionHeader(
            title: S.of(locale, 'pricing_title'),
            subtitle: S.of(locale, 'pricing_subtitle'),
          ),
          const SizedBox(height: 56),
          if (mobile)
            Column(
              children: plans
                  .map((p) => Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: _PricingCard(plan: p, locale: locale),
                      ))
                  .toList(),
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: plans
                  .map((p) => Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            left: plans.indexOf(p) == 0 ? 0 : 8,
                            right: plans.indexOf(p) == plans.length - 1 ? 0 : 8,
                            top: p.popular ? 0 : 24,
                          ),
                          child: _PricingCard(plan: p, locale: locale),
                        ),
                      ))
                  .toList(),
            ),
        ],
      ),
    );
  }
}

class _Plan {
  final String nameKey;
  final String? price;
  final bool popular;
  final List<({String label, bool included})> features;

  const _Plan({
    required this.nameKey,
    required this.price,
    required this.popular,
    required this.features,
  });
}

class _PricingCard extends StatefulWidget {
  final _Plan plan;
  final String locale;

  const _PricingCard({required this.plan, required this.locale});

  @override
  State<_PricingCard> createState() => _PricingCardState();
}

class _PricingCardState extends State<_PricingCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final plan = widget.plan;
    final locale = widget.locale;
    final isEnterprise = plan.price == null;
    final popular = plan.popular;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: popular ? AppColors.dark : AppColors.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: popular
                ? AppColors.amber.withOpacity(0.5)
                : (_hovered ? AppColors.blue.withOpacity(0.3) : AppColors.border),
            width: popular ? 2 : 1,
          ),
          boxShadow: popular || _hovered
              ? [
                  BoxShadow(
                    color: popular
                        ? AppColors.amber.withOpacity(0.15)
                        : AppColors.blue.withOpacity(0.08),
                    blurRadius: 32,
                    offset: const Offset(0, 12),
                  )
                ]
              : [],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            if (popular)
              Positioned(
                top: -14,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.amber,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      S.of(locale, 'pricing_popular'),
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    S.of(locale, plan.nameKey),
                    style: GoogleFonts.inter(
                      color: popular ? Colors.white : AppColors.text,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (isEnterprise)
                    Text(
                      S.of(locale, 'pricing_enterprise'),
                      style: GoogleFonts.inter(
                        color: popular ? Colors.white : AppColors.text,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    )
                  else
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          plan.price!,
                          style: GoogleFonts.inter(
                            color: popular ? Colors.white : AppColors.text,
                            fontSize: 40,
                            fontWeight: FontWeight.w800,
                            height: 1,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6, left: 4),
                          child: Text(
                            S.of(locale, 'pricing_month'),
                            style: GoogleFonts.inter(
                              color: popular ? Colors.white54 : AppColors.textMuted,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 28),
                  const Divider(height: 1),
                  const SizedBox(height: 20),
                  ...plan.features.map((f) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Icon(
                              f.included ? Icons.check_circle_rounded : Icons.remove_rounded,
                              size: 18,
                              color: f.included
                                  ? (popular ? AppColors.amber : AppColors.blue)
                                  : Colors.grey.withOpacity(0.5),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                f.label,
                                style: GoogleFonts.inter(
                                  color: f.included
                                      ? (popular ? Colors.white : AppColors.text)
                                      : Colors.grey,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: _PriceButton(
                      label: isEnterprise
                          ? S.of(locale, 'pricing_cta_contact')
                          : S.of(locale, 'pricing_cta_start'),
                      popular: popular,
                      enterprise: isEnterprise,
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

class _PriceButton extends StatefulWidget {
  final String label;
  final bool popular;
  final bool enterprise;

  const _PriceButton({
    required this.label,
    required this.popular,
    required this.enterprise,
  });

  @override
  State<_PriceButton> createState() => _PriceButtonState();
}

class _PriceButtonState extends State<_PriceButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color textColor = Colors.white;

    if (widget.popular) {
      bg = _hovered ? const Color(0xFFE09610) : AppColors.amber;
    } else if (widget.enterprise) {
      bg = _hovered ? AppColors.blue.withOpacity(0.9) : AppColors.blue;
    } else {
      bg = _hovered ? AppColors.dark : const Color(0xFFF0F4FF);
      textColor = _hovered ? Colors.white : AppColors.dark;
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              widget.label,
              style: GoogleFonts.inter(
                color: textColor,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
