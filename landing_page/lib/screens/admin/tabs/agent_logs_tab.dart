import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../core/colors.dart';

class AgentLogsTab extends StatelessWidget {
  const AgentLogsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('agent_logs')
          .orderBy('timestamp', descending: true)
          .limit(50)
          .snapshots(),
      builder: (context, snap) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 24, 24, 4),
              child: Text(
                'Logs de Agentes',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 0, 24, 0),
              child: Text(
                'Últimas 50 invocações em tempo real',
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ),
            const SizedBox(height: 12),
            // Header row
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Row(
                children: [
                  SizedBox(width: 90, child: Text('Agente', style: TextStyle(color: Colors.white38, fontSize: 11))),
                  SizedBox(width: 12),
                  Expanded(child: Text('Sessão', style: TextStyle(color: Colors.white38, fontSize: 11))),
                  SizedBox(width: 8),
                  SizedBox(width: 80, child: Text('Tenant', style: TextStyle(color: Colors.white38, fontSize: 11))),
                  SizedBox(width: 12),
                  SizedBox(width: 56, child: Text('Latência', style: TextStyle(color: Colors.white38, fontSize: 11))),
                  SizedBox(width: 12),
                  SizedBox(width: 40, child: Text('Há', textAlign: TextAlign.right, style: TextStyle(color: Colors.white38, fontSize: 11))),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Divider(color: Colors.white10, height: 1),
            ),
            const SizedBox(height: 4),
            if (snap.connectionState == ConnectionState.waiting)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (!snap.hasData || snap.data!.docs.isEmpty)
              const Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.list_alt_outlined, color: Colors.white12, size: 48),
                      SizedBox(height: 12),
                      Text('Nenhum log ainda.', style: TextStyle(color: Colors.white38)),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  itemCount: snap.data!.docs.length,
                  itemBuilder: (context, i) {
                    final d = snap.data!.docs[i].data() as Map<String, dynamic>;
                    return _LogEntry(data: d);
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}

// Reuse the same colour map as conversations tab
const _kAgentColors = <String, Color>{
  'suporte': Color(0xFF42A5F5),
  'comercial': Color(0xFFAB47BC),
  'juridico': Color(0xFFFFA726),
  'rh': Color(0xFF26A69A),
  'financeiro': Color(0xFF66BB6A),
  'marketing': Color(0xFFEC407A),
  'orquestrador': Color(0xFF78909C),
};

class _LogEntry extends StatelessWidget {
  final Map<String, dynamic> data;
  const _LogEntry({required this.data});

  @override
  Widget build(BuildContext context) {
    final agent = data['agent'] as String? ?? '?';
    final tenantId = data['tenant_id'] as String? ?? '—';
    final sessionId = data['session_id'] as String? ?? '—';
    final latencyMs = data['latency_ms'] as int? ?? 0;
    final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
    final color = _kAgentColors[agent] ?? const Color(0xFF78909C);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          // Agent pill
          Container(
            width: 90,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              agent,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Session ID
          Expanded(
            child: Text(
              sessionId.length > 26 ? '${sessionId.substring(0, 26)}…' : sessionId,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 11,
                fontFamily: 'monospace',
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Tenant
          SizedBox(
            width: 80,
            child: Text(
              tenantId.length > 10 ? '${tenantId.substring(0, 10)}…' : tenantId,
              style: const TextStyle(color: Colors.white38, fontSize: 11),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
          // Latency badge
          Container(
            width: 56,
            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
            decoration: BoxDecoration(
              color: _latencyColor(latencyMs).withOpacity(0.15),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              '${latencyMs}ms',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _latencyColor(latencyMs),
                fontSize: 11,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Time ago
          SizedBox(
            width: 40,
            child: Text(
              timestamp != null ? _timeAgo(timestamp) : '—',
              textAlign: TextAlign.right,
              style: const TextStyle(color: Colors.white38, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Color _latencyColor(int ms) {
    if (ms < 1000) return const Color(0xFF66BB6A);
    if (ms < 3000) return const Color(0xFFFFA726);
    return const Color(0xFFEF5350);
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    return '${diff.inHours}h';
  }
}
