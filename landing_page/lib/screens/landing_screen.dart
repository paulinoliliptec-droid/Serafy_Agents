import 'package:flutter/material.dart';

import '../sections/agents_section.dart';
import '../sections/countries_section.dart';
import '../sections/hero_section.dart';
import '../sections/pricing_section.dart';
import '../sections/sectors_section.dart';
import '../sections/social_proof_section.dart';
import '../widgets/footer_widget.dart';
import '../widgets/navbar.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  final _scrollController = ScrollController();

  // Section keys for scroll-to-section
  final _productKey   = GlobalKey();
  final _pricingKey   = GlobalKey();
  final _countriesKey = GlobalKey();
  final _contactKey   = GlobalKey();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollTo(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeInOutCubic,
      alignment: 0.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Scrollable content — offset by navbar height
          SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 68), // navbar height offset
                const HeroSection(),
                SectorsSection(key: _productKey),
                const AgentsSection(),
                const SocialProofSection(),
                PricingSection(key: _pricingKey),
                CountriesSection(key: _countriesKey),
                FooterWidget(
                  key: _contactKey,
                  onProduct:   () => _scrollTo(_productKey),
                  onPricing:   () => _scrollTo(_pricingKey),
                  onCountries: () => _scrollTo(_countriesKey),
                  onContact:   () => _scrollTo(_contactKey),
                ),
              ],
            ),
          ),
          // Fixed navbar on top
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Navbar(
              onProduct:   () => _scrollTo(_productKey),
              onPricing:   () => _scrollTo(_pricingKey),
              onCountries: () => _scrollTo(_countriesKey),
              onContact:   () => _scrollTo(_contactKey),
            ),
          ),
        ],
      ),
    );
  }
}
