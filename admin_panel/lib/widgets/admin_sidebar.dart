import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/constants.dart';

class AdminSidebar extends StatelessWidget {
  const AdminSidebar({super.key});

  static const _items = [
    (icon: Icons.dashboard_rounded, label: 'Dashboard', route: AppRoutes.dashboard),
    (icon: Icons.people_rounded, label: 'Clientes', route: AppRoutes.clients),
    (icon: Icons.credit_card_rounded, label: 'Faturação', route: AppRoutes.billing),
    (icon: Icons.vpn_key_rounded, label: 'API Keys', route: AppRoutes.apiKeys),
    (icon: Icons.palette_rounded, label: 'Branding', route: AppRoutes.branding),
  ];

  @override
  Widget build(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;

    return Container(
      width: 220,
      color: AppColors.sidebarBg,
      child: Column(
        children: [
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const FlutterLogo(size: 28),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'agentOS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.adminBadge,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'ADMIN',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: _items.map((item) {
                final active = loc.startsWith(item.route);
                return _SidebarTile(
                  icon: item.icon,
                  label: item.label,
                  active: active,
                  onTap: () => context.go(item.route),
                );
              }).toList(),
            ),
          ),
          const Divider(color: Colors.white12),
          _SidebarTile(
            icon: Icons.logout_rounded,
            label: 'Sair',
            active: false,
            onTap: () async {
              // handled in scaffold
              context.go(AppRoutes.login);
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _SidebarTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _SidebarTile({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: active ? AppColors.sidebarActive : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon,
                color: active ? Colors.white : Colors.white54, size: 20),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: active ? Colors.white : Colors.white54,
                fontSize: 14,
                fontWeight: active ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
