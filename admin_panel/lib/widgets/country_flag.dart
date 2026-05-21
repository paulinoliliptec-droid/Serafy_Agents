import 'package:flutter/material.dart';

import '../core/constants.dart';

class CountryFlag extends StatelessWidget {
  final String countryCode;
  final double size;

  const CountryFlag({super.key, required this.countryCode, this.size = 20});

  @override
  Widget build(BuildContext context) {
    final entry = kCplpCountries[countryCode];
    if (entry == null) {
      return Text(countryCode, style: TextStyle(fontSize: size * 0.7));
    }
    return Text(entry.$2, style: TextStyle(fontSize: size));
  }
}
