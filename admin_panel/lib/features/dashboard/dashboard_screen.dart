import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../providers/dashboard_provider.dart';
import '../../widgets/admin_scaffold.dart';
import '../../widgets/country_flag.dart';
import '../../widgets/stat_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(dashboardStatsProvider);
    final historyAsync = ref.watch(conversationHistoryProvider);

    return AdminScaffold(
      title: 'Dashboard',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          statsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Erro: $e'),
            data: (stats) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // KPI cards
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    _kpiCard(context, 'MRR Total',
                        '\$${stats.totalMrr.toStringAsFixed(0)}',
                        Icons.trending_up, Colors.green),
                    _kpiCard(context, 'Clientes',
                        '${stats.totalClients}', Icons.people, Colors.blue),
                    _kpiCard(context, 'Activos',
                        '${stats.activeClients}', Icons.check_circle, Colors.teal),
                    _kpiCard(context, 'Conversas (mês)',
                        '${stats.totalConversations}', Icons.chat_bubble, Colors.purple),
                    _kpiCard(context, 'Custo LLM (mês)',
                        '\$${stats.totalLlmCost.toStringAsFixed(2)}',
                        Icons.memory, Colors.orange),
                  ],
                ),
                const SizedBox(height: 32),
                // Country breakdown
                Text('Clientes por país',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                _CountryBreakdown(data: stats.clientsByCountry),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Text('Conversas por dia (últimos 30 dias)',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          historyAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Erro: $e'),
            data: (history) => SizedBox(
              height: 200,
              child: history.isEmpty
                  ? const Center(child: Text('Sem dados'))
                  : _ConversationsChart(history: history),
            ),
          ),
        ],
      ),
    );
  }

  Widget _kpiCard(BuildContext context, String label, String value,
      IconData icon, Color color) {
    return SizedBox(
      width: 180,
      child: StatCard(label: label, value: value, icon: icon, iconColor: color),
    );
  }
}

class _CountryBreakdown extends StatelessWidget {
  final Map<String, int> data;
  const _CountryBreakdown({required this.data});

  @override
  Widget build(BuildContext context) {
    final sorted = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: sorted.map((e) {
        final country = kCplpCountries[e.key];
        return Chip(
          avatar: CountryFlag(countryCode: e.key, size: 18),
          label: Text(
              '${country?.$1 ?? e.key}  ${e.value}',
              style: const TextStyle(fontSize: 13)),
        );
      }).toList(),
    );
  }
}

class _ConversationsChart extends StatelessWidget {
  final List<ConversationPoint> history;
  const _ConversationsChart({required this.history});

  @override
  Widget build(BuildContext context) {
    final spots = history
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.count.toDouble()))
        .toList();

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Theme.of(context).colorScheme.primary,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
            ),
          ),
        ],
      ),
    );
  }
}
