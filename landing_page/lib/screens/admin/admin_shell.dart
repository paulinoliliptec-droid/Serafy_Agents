import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/colors.dart';
import '../../providers/admin_auth_provider.dart';
import 'tabs/agent_logs_tab.dart';
import 'tabs/conversations_tab.dart';
import 'tabs/metrics_tab.dart';
import 'tabs/system_status_tab.dart';

class AdminShell extends ConsumerStatefulWidget {
  const AdminShell({super.key});

  @override
  ConsumerState<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends ConsumerState<AdminShell> {
  int _selectedIndex = 0;

  static const _tabs = [
    SystemStatusTab(),
    ConversationsTab(),
    AgentLogsTab(),
    MetricsTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.blue,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: AppColors.dark,
        cardColor: AppColors.darkAlt,
        dividerColor: Colors.white10,
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      ),
      child: Scaffold(
        backgroundColor: AppColors.dark,
        appBar: AppBar(
          backgroundColor: AppColors.darkAlt,
          elevation: 0,
          titleSpacing: 20,
          title: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.blue,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.bolt, color: Colors.white, size: 16),
              ),
              const SizedBox(width: 10),
              const Text(
                'Serafy Admin',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.blue.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'INTERNO',
                  style: TextStyle(color: AppColors.blue, fontSize: 9, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          actions: [
            TextButton.icon(
              onPressed: () {
                ref.read(adminAuthProvider.notifier).logout();
                context.go('/admin/login');
              },
              icon: const Icon(Icons.logout, color: Colors.white38, size: 15),
              label: const Text('Sair', style: TextStyle(color: Colors.white38, fontSize: 13)),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Row(
          children: [
            NavigationRail(
              backgroundColor: AppColors.darkAlt,
              selectedIndex: _selectedIndex,
              onDestinationSelected: (i) => setState(() => _selectedIndex = i),
              labelType: NavigationRailLabelType.all,
              minWidth: 80,
              selectedIconTheme: const IconThemeData(color: AppColors.blue),
              selectedLabelTextStyle: const TextStyle(
                color: AppColors.blue,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              unselectedIconTheme: const IconThemeData(color: Colors.white38),
              unselectedLabelTextStyle: const TextStyle(color: Colors.white38, fontSize: 11),
              destinations: const [
                NavigationRailDestination(
                  icon: Icon(Icons.monitor_heart_outlined),
                  selectedIcon: Icon(Icons.monitor_heart),
                  label: Text('Estado'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.chat_bubble_outline),
                  selectedIcon: Icon(Icons.chat_bubble),
                  label: Text('Conversas'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.list_alt_outlined),
                  selectedIcon: Icon(Icons.list_alt),
                  label: Text('Logs'),
                ),
                NavigationRailDestination(
                  icon: Icon(Icons.bar_chart_outlined),
                  selectedIcon: Icon(Icons.bar_chart),
                  label: Text('Métricas'),
                ),
              ],
            ),
            const VerticalDivider(width: 1, thickness: 1, color: Colors.white10),
            Expanded(
              child: IndexedStack(
                index: _selectedIndex,
                children: _tabs,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
