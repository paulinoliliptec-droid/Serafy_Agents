import 'package:flutter/material.dart';

class AppColors {
  static const sidebarBg = Color(0xFF0A1628);
  static const sidebarActive = Color(0xFF162540);
  static const sidebarText = Colors.white;
  static const sidebarSubtext = Color(0xFF8EA9C4);
  static const adminBadge = Color(0xFFF5A623);
  static const accent = Color(0xFF3B82F6);
  static const success = Color(0xFF10B981);
  static const danger = Color(0xFFEF4444);
  static const warning = Color(0xFFF59E0B);
  static const surface = Color(0xFFF8FAFC);
  static const cardBg = Colors.white;
}

class AppRoutes {
  static const login = '/login';
  static const unauthorized = '/unauthorized';
  static const dashboard = '/';
  static const clients = '/clients';
  static const clientDetail = '/clients/:id';
  static const agents = '/clients/:id/agents';
  static const branding = '/branding';
  static const apiKeys = '/api-keys';
  static const billing = '/billing';
}

const kCplpCountries = {
  'AO': ('Angola', '🇦🇴'),
  'PT': ('Portugal', '🇵🇹'),
  'MZ': ('Moçambique', '🇲🇿'),
  'CV': ('Cabo Verde', '🇨🇻'),
  'ST': ('São Tomé', '🇸🇹'),
  'GW': ('Guiné-Bissau', '🇬🇼'),
  'BR': ('Brasil', '🇧🇷'),
};

const kPlans = ['free', 'pro', 'enterprise'];
const kAgentNames = ['suporte', 'comercial', 'juridico', 'rh', 'financeiro', 'marketing'];
