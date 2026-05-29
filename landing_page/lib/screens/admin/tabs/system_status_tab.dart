import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/colors.dart';

class SystemStatusTab extends StatelessWidget {
  const SystemStatusTab({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('system_status')
          .doc('current')
          .snapshots(),
      builder: (context, snap) {
        final data = snap.data?.data() as Map<String, dynamic>?;
        final updatedAt = (data?['updated_at'] as Timestamp?)?.toDate();

        return ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Row(
              children: [
                const Text(
                  'Estado do Sistema',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                if (updatedAt != null)
                  Text(
                    'Actualizado: ${DateFormat('HH:mm:ss').format(updatedAt.toLocal())}',
                    style: const TextStyle(color: Colors.white38, fontSize: 12),
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
            else if (data == null)
              _NoDataCard()
            else
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  _StatusCard(
                    label: 'Cloud Run',
                    icon: Icons.cloud_outlined,
                    active: data['cloud_run_healthy'] as bool? ?? false,
                    detail: 'API Backend',
                  ),
                  _StatusCard(
                    label: 'WhatsApp',
                    icon: Icons.chat_rounded,
                    active: data['whatsapp_configured'] as bool? ?? false,
                    detail: 'Meta Business API',
                  ),
                  _StatusCard(
                    label: 'OpenAI',
                    icon: Icons.psychology_outlined,
                    active: data['openai_active'] as bool? ?? false,
                    detail: 'GPT-4o · Orquestrador',
                  ),
                  _StatusCard(
                    label: 'Gemini',
                    icon: Icons.auto_awesome_outlined,
                    active: data['gemini_active'] as bool? ?? false,
                    detail: 'Fallback jurídico CPLP',
                  ),
                ],
              ),
          ],
        );
      },
    );
  }
}

class _NoDataCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.darkAlt,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: Colors.white38, size: 18),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Sem dados de estado. O backend ainda não reportou ao Firestore.',
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final String detail;

  const _StatusCard({
    required this.label,
    required this.icon,
    required this.active,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? const Color(0xFF66BB6A) : const Color(0xFFEF5350);
    return Container(
      width: 200,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.darkAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const Spacer(),
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  boxShadow: active
                      ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 6)]
                      : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            active ? 'Online' : 'Offline',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            detail,
            style: const TextStyle(color: Colors.white38, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
