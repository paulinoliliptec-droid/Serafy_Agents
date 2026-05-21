import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../models/agent_config.dart';
import '../../services/firestore_service.dart';
import '../../widgets/admin_scaffold.dart';

final _agentsProvider =
    StreamProvider.family<List<AgentConfig>, String>((ref, clientId) {
  return FirestoreService().agentsStream(clientId);
});

class AgentsScreen extends ConsumerWidget {
  final String clientId;
  const AgentsScreen({super.key, required this.clientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agentsAsync = ref.watch(_agentsProvider(clientId));

    return AdminScaffold(
      title: 'Agentes',
      child: agentsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Text('Erro: $e'),
        data: (agents) {
          // Ensure all standard agents appear even if not yet in Firestore
          final names = agents.map((a) => a.name).toSet();
          final allAgents = [
            ...agents,
            ...kAgentNames
                .where((n) => !names.contains(n))
                .map((n) => AgentConfig(
                    name: n, enabled: true, prompt: '', kiesse: false)),
          ];
          allAgents.sort((a, b) =>
              kAgentNames.indexOf(a.name).compareTo(kAgentNames.indexOf(b.name)));

          return ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: allAgents.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) =>
                _AgentCard(clientId: clientId, agent: allAgents[i]),
          );
        },
      ),
    );
  }
}

class _AgentCard extends StatelessWidget {
  final String clientId;
  final AgentConfig agent;

  const _AgentCard({required this.clientId, required this.agent});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ExpansionTile(
        leading: Icon(
          _agentIcon(agent.name),
          color: agent.enabled
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        title: Row(
          children: [
            Text(agent.name,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(width: 8),
            if (!agent.enabled)
              const Chip(
                  label: Text('Desactivado', style: TextStyle(fontSize: 11)),
                  padding: EdgeInsets.zero),
          ],
        ),
        trailing: Switch(
          value: agent.enabled,
          onChanged: (v) => _updateField(context, enabled: v),
        ),
        children: [
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Kiesse toggle (only for juridico)
                if (agent.name == 'juridico') ...[
                  Row(
                    children: [
                      const Icon(Icons.gavel, size: 18),
                      const SizedBox(width: 8),
                      const Expanded(child: Text('Usar Kiesse API (jurídico)')),
                      Switch(
                        value: agent.kiesse,
                        onChanged: (v) => _updateField(context, kiesse: v),
                      ),
                    ],
                  ),
                  const Divider(),
                ],
                // Prompt editor
                Text('System prompt',
                    style: Theme.of(context).textTheme.labelMedium),
                const SizedBox(height: 8),
                _PromptEditor(
                  clientId: clientId,
                  agent: agent,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _agentIcon(String name) => switch (name) {
        'suporte' => Icons.support_agent,
        'comercial' => Icons.storefront,
        'juridico' => Icons.gavel,
        'rh' => Icons.badge,
        'financeiro' => Icons.account_balance,
        'marketing' => Icons.campaign,
        _ => Icons.smart_toy,
      };

  void _updateField(BuildContext context,
      {bool? enabled, bool? kiesse}) {
    final updated = agent.copyWith(enabled: enabled, kiesse: kiesse);
    FirestoreService().updateAgent(clientId, agent.name, updated.toMap());
  }
}

class _PromptEditor extends StatefulWidget {
  final String clientId;
  final AgentConfig agent;

  const _PromptEditor({required this.clientId, required this.agent});

  @override
  State<_PromptEditor> createState() => _PromptEditorState();
}

class _PromptEditorState extends State<_PromptEditor> {
  late final TextEditingController _ctrl;
  bool _dirty = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.agent.prompt);
    _ctrl.addListener(() => setState(() => _dirty = _ctrl.text != widget.agent.prompt));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _ctrl,
          maxLines: 6,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'System prompt para este agente...',
          ),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton(
            onPressed: (_dirty && !_saving) ? _save : null,
            child: _saving
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Guardar prompt'),
          ),
        ),
      ],
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final updated = widget.agent.copyWith(prompt: _ctrl.text);
      await FirestoreService()
          .updateAgent(widget.clientId, widget.agent.name, updated.toMap());
      setState(() => _dirty = false);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
