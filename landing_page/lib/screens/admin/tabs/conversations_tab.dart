import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../core/colors.dart';

class ConversationsTab extends StatelessWidget {
  const ConversationsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('conversations')
          .orderBy('updated_at', descending: true)
          .limit(30)
          .snapshots(),
      builder: (context, snap) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Row(
                children: [
                  const Text(
                    'Conversas',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (snap.hasData)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.blue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${snap.data!.docs.length}',
                        style: const TextStyle(color: AppColors.blue, fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 0, 24, 0),
              child: Text(
                'Ordenadas por actividade recente',
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ),
            const SizedBox(height: 16),
            if (snap.connectionState == ConnectionState.waiting)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (!snap.hasData || snap.data!.docs.isEmpty)
              const Expanded(
                child: _EmptyState(
                  icon: Icons.chat_bubble_outline,
                  message: 'Nenhuma conversa ainda.',
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  itemCount: snap.data!.docs.length,
                  separatorBuilder: (_, __) =>
                      const Divider(color: Colors.white10, height: 1),
                  itemBuilder: (context, i) {
                    final doc = snap.data!.docs[i];
                    return _ConversationRow(
                      id: doc.id,
                      data: doc.data() as Map<String, dynamic>,
                    );
                  },
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ConversationRow extends StatelessWidget {
  final String id;
  final Map<String, dynamic> data;

  const _ConversationRow({required this.id, required this.data});

  @override
  Widget build(BuildContext context) {
    final channel = data['channel'] as String? ?? 'chat';
    final lastAgent = data['last_agent'] as String? ?? '—';
    final lastMessage = data['last_message'] as String? ?? '';
    final status = data['status'] as String? ?? 'active';
    final count = data['message_count'] as int? ?? 0;
    final updatedAt = (data['updated_at'] as Timestamp?)?.toDate();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          _ChannelIcon(channel: channel),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  id.length > 22 ? '${id.substring(0, 22)}…' : id,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  lastMessage.isEmpty ? '—' : lastMessage,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _AgentChip(agent: lastAgent),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _StatusLabel(status: status),
              const SizedBox(height: 3),
              Text(
                '$count msg${count != 1 ? 's' : ''}',
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
              if (updatedAt != null)
                Text(
                  _timeAgo(updatedAt),
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'agora';
    if (diff.inMinutes < 60) return 'há ${diff.inMinutes}m';
    if (diff.inHours < 24) return 'há ${diff.inHours}h';
    return 'há ${diff.inDays}d';
  }
}

class _ChannelIcon extends StatelessWidget {
  final String channel;
  const _ChannelIcon({required this.channel});

  @override
  Widget build(BuildContext context) {
    final isWhatsApp = channel == 'whatsapp';
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: isWhatsApp
            ? const Color(0xFF1B5E20)
            : AppColors.blue.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        isWhatsApp ? Icons.chat_rounded : Icons.chat_bubble_outline,
        color: isWhatsApp ? const Color(0xFF66BB6A) : AppColors.blue,
        size: 18,
      ),
    );
  }
}

// Agent name → colour mapping (const-safe hex values)
const _kAgentColors = <String, Color>{
  'suporte': Color(0xFF42A5F5),
  'comercial': Color(0xFFAB47BC),
  'juridico': Color(0xFFFFA726),
  'rh': Color(0xFF26A69A),
  'financeiro': Color(0xFF66BB6A),
  'marketing': Color(0xFFEC407A),
  'orquestrador': Color(0xFF78909C),
};

class _AgentChip extends StatelessWidget {
  final String agent;
  const _AgentChip({required this.agent});

  @override
  Widget build(BuildContext context) {
    final color = _kAgentColors[agent] ?? const Color(0xFF78909C);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        agent,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w500),
      ),
    );
  }
}

class _StatusLabel extends StatelessWidget {
  final String status;
  const _StatusLabel({required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      'resolved' => (const Color(0xFF66BB6A), 'resolvida'),
      'escalated' => (const Color(0xFFFFA726), 'escalada'),
      _ => (AppColors.blue, 'activa'),
    };
    return Text(
      label,
      style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w500),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white12, size: 48),
          const SizedBox(height: 12),
          Text(message, style: const TextStyle(color: Colors.white38)),
        ],
      ),
    );
  }
}
