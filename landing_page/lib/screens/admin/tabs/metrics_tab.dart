import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/colors.dart';

class MetricsTab extends StatelessWidget {
  const MetricsTab({super.key});

  String get _todayKey => DateFormat('yyyy-MM-dd').format(DateTime.now());

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('metrics')
          .doc('today')
          .snapshots(),
      builder: (context, snap) {
        final data = snap.data?.data() as Map<String, dynamic>?;
        final docDate = data?['date'] as String?;
        final isToday = docDate == _todayKey;

        // Use zeros if the doc belongs to a previous day
        final totalMessages = isToday ? (data?['total_messages'] as int? ?? 0) : 0;
        final totalLatency = isToday ? (data?['total_latency_ms'] as int? ?? 0) : 0;
        final resolved = isToday ? (data?['resolved_count'] as int? ?? 0) : 0;
        final escalated = isToday ? (data?['escalated_count'] as int? ?? 0) : 0;
        final agentBreakdown = isToday
            ? (data?['agent_breakdown'] as Map<String, dynamic>? ?? {})
            : <String, dynamic>{};
        final avgLatency =
            totalMessages > 0 ? totalLatency ~/ totalMessages : 0;

        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Row(
              children: [
                const Text(
                  'Métricas de Hoje',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  _todayKey,
                  style: const TextStyle(color: Colors.white38, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (snap.connectionState == ConnectionState.waiting)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(48),
                  child: CircularProgressIndicator(),
                ),
              )
            else ...[
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _MetricCard(
                    label: 'Mensagens',
                    value: '$totalMessages',
                    icon: Icons.chat_bubble_outline,
                    color: AppColors.blue,
                  ),
                  _MetricCard(
                    label: 'Latência Média',
                    value: avgLatency == 0 ? '—' : '${avgLatency}ms',
                    icon: Icons.timer_outlined,
                    color: _latencyColor(avgLatency),
                  ),
                  _MetricCard(
                    label: 'Resolvidas',
                    value: '$resolved',
                    icon: Icons.check_circle_outline,
                    color: const Color(0xFF66BB6A),
                  ),
                  _MetricCard(
                    label: 'Escaladas',
                    value: '$escalated',
                    icon: Icons.escalator_warning_outlined,
                    color: const Color(0xFFFFA726),
                  ),
                ],
              ),
              if (agentBreakdown.isNotEmpty) ...[
                const SizedBox(height: 32),
                const Text(
                  'Mensagens por agente',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                ...agentBreakdown.entries.map(
                  (e) => _AgentBar(
                    agent: e.key,
                    count: (e.value as num).toInt(),
                    total: totalMessages,
                  ),
                ),
              ] else if (totalMessages == 0) ...[
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.darkAlt,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.white38, size: 18),
                      SizedBox(width: 12),
                      Text(
                        'Nenhuma mensagem processada hoje ainda.',
                        style: TextStyle(color: Colors.white54, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ],
        );
      },
    );
  }

  Color _latencyColor(int ms) {
    if (ms == 0) return Colors.grey;
    if (ms < 1000) return const Color(0xFF66BB6A);
    if (ms < 3000) return const Color(0xFFFFA726);
    return const Color(0xFFEF5350);
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.darkAlt,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

const _kAgentColors = <String, Color>{
  'suporte': Color(0xFF42A5F5),
  'comercial': Color(0xFFAB47BC),
  'juridico': Color(0xFFFFA726),
  'rh': Color(0xFF26A69A),
  'financeiro': Color(0xFF66BB6A),
  'marketing': Color(0xFFEC407A),
  'orquestrador': Color(0xFF78909C),
};

class _AgentBar extends StatelessWidget {
  final String agent;
  final int count;
  final int total;

  const _AgentBar({
    required this.agent,
    required this.count,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? count / total : 0.0;
    final color = _kAgentColors[agent] ?? const Color(0xFF78909C);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: 84,
            child: Text(
              agent,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: pct,
                backgroundColor: Colors.white10,
                valueColor: AlwaysStoppedAnimation(color),
                minHeight: 8,
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 28,
            child: Text(
              '$count',
              textAlign: TextAlign.right,
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
