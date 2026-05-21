import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../models/client.dart';
import '../../providers/clients_provider.dart';
import '../../services/firestore_service.dart';
import '../../widgets/admin_scaffold.dart';
import '../../widgets/country_flag.dart';

class ClientsScreen extends ConsumerWidget {
  const ClientsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientsAsync = ref.watch(clientsProvider);

    return AdminScaffold(
      title: 'Clientes',
      actions: [
        FilledButton.icon(
          onPressed: () => _showCreateDialog(context, ref),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Novo cliente'),
        ),
      ],
      child: clientsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Text('Erro: $e'),
        data: (clients) => _ClientsTable(clients: clients),
      ),
    );
  }

  void _showCreateDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => _CreateClientDialog(),
    );
  }
}

class _ClientsTable extends StatelessWidget {
  final List<Client> clients;
  const _ClientsTable({required this.clients});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(
              Theme.of(context).colorScheme.surfaceContainerHighest),
          columns: const [
            DataColumn(label: Text('Nome')),
            DataColumn(label: Text('País')),
            DataColumn(label: Text('Plano')),
            DataColumn(label: Text('Estado')),
            DataColumn(label: Text('MRR')),
            DataColumn(label: Text('Acções')),
          ],
          rows: clients.map((c) => _clientRow(context, c)).toList(),
        ),
      ),
    );
  }

  DataRow _clientRow(BuildContext context, Client c) {
    return DataRow(
      cells: [
        DataCell(
          InkWell(
            onTap: () => context.go('/clients/${c.id}'),
            child: Text(c.name,
                style: const TextStyle(
                    decoration: TextDecoration.underline,
                    fontWeight: FontWeight.w500)),
          ),
        ),
        DataCell(Row(children: [
          CountryFlag(countryCode: c.country),
          const SizedBox(width: 6),
          Text(kCplpCountries[c.country]?.$1 ?? c.country),
        ])),
        DataCell(_PlanChip(plan: c.plan)),
        DataCell(_StatusChip(status: c.status)),
        DataCell(Text('\$${c.mrr.toStringAsFixed(0)}')),
        DataCell(_ActionMenu(client: c)),
      ],
    );
  }
}

class _PlanChip extends StatelessWidget {
  final String plan;
  const _PlanChip({required this.plan});

  @override
  Widget build(BuildContext context) {
    final color = switch (plan) {
      'enterprise' => Colors.purple,
      'pro' => Colors.blue,
      'starter' => Colors.teal,
      _ => Colors.grey,
    };
    return Chip(
      label: Text(plan, style: const TextStyle(fontSize: 12)),
      backgroundColor: color.withOpacity(0.12),
      side: BorderSide(color: color.withOpacity(0.3)),
      padding: EdgeInsets.zero,
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final active = status == 'active';
    return Chip(
      label: Text(active ? 'Activo' : 'Suspenso',
          style: const TextStyle(fontSize: 12)),
      backgroundColor:
          active ? Colors.green.withOpacity(0.12) : Colors.red.withOpacity(0.12),
      side: BorderSide(
          color: active
              ? Colors.green.withOpacity(0.4)
              : Colors.red.withOpacity(0.4)),
      padding: EdgeInsets.zero,
    );
  }
}

class _ActionMenu extends StatelessWidget {
  final Client client;
  const _ActionMenu({required this.client});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: (v) => _handle(context, v),
      itemBuilder: (_) => [
        const PopupMenuItem(value: 'detail', child: Text('Ver detalhes')),
        const PopupMenuItem(value: 'agents', child: Text('Agentes')),
        const PopupMenuItem(value: 'plan', child: Text('Mudar plano')),
        PopupMenuItem(
          value: client.isActive ? 'suspend' : 'activate',
          child: Text(client.isActive ? 'Suspender' : 'Activar'),
        ),
      ],
      child: const Icon(Icons.more_vert),
    );
  }

  Future<void> _handle(BuildContext context, String action) async {
    final svc = FirestoreService();
    switch (action) {
      case 'detail':
        context.go('/clients/${client.id}');
      case 'agents':
        context.go('/clients/${client.id}/agents');
      case 'suspend':
        await svc.suspendClient(client.id);
      case 'activate':
        await svc.activateClient(client.id);
      case 'plan':
        if (context.mounted) _showPlanDialog(context, client, svc);
    }
  }

  void _showPlanDialog(
      BuildContext context, Client client, FirestoreService svc) {
    showDialog(
      context: context,
      builder: (_) => _ChangePlanDialog(client: client, svc: svc),
    );
  }
}

class _CreateClientDialog extends ConsumerStatefulWidget {
  @override
  ConsumerState<_CreateClientDialog> createState() =>
      _CreateClientDialogState();
}

class _CreateClientDialogState extends ConsumerState<_CreateClientDialog> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  String _country = 'AO';
  String _plan = 'starter';
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Novo cliente'),
      content: Form(
        key: _form,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Nome'),
              validator: (v) => (v == null || v.isEmpty) ? 'Obrigatório' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _country,
              decoration: const InputDecoration(labelText: 'País'),
              items: kCplpCountries.entries
                  .map((e) => DropdownMenuItem(
                        value: e.key,
                        child: Row(children: [
                          CountryFlag(countryCode: e.key),
                          const SizedBox(width: 8),
                          Text(e.value.$1),
                        ]),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _country = v!),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _plan,
              decoration: const InputDecoration(labelText: 'Plano'),
              items: ['free', 'starter', 'pro', 'enterprise']
                  .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                  .toList(),
              onChanged: (v) => setState(() => _plan = v!),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar')),
        FilledButton(
          onPressed: _saving ? null : _create,
          child: const Text('Criar'),
        ),
      ],
    );
  }

  Future<void> _create() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await FirestoreService().createClient({
        'name': _name.text.trim(),
        'country': _country,
        'plan': _plan,
      });
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _ChangePlanDialog extends StatefulWidget {
  final Client client;
  final FirestoreService svc;
  const _ChangePlanDialog({required this.client, required this.svc});

  @override
  State<_ChangePlanDialog> createState() => _ChangePlanDialogState();
}

class _ChangePlanDialogState extends State<_ChangePlanDialog> {
  late String _plan;
  final _mrr = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _plan = widget.client.plan;
    _mrr.text = widget.client.mrr.toStringAsFixed(0);
  }

  @override
  void dispose() {
    _mrr.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Plano — ${widget.client.name}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            value: _plan,
            items: ['free', 'starter', 'pro', 'enterprise']
                .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                .toList(),
            onChanged: (v) => setState(() => _plan = v!),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _mrr,
            decoration: const InputDecoration(labelText: 'MRR (USD)', prefixText: '\$'),
            keyboardType: TextInputType.number,
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar')),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: const Text('Guardar'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final mrr = double.tryParse(_mrr.text) ?? widget.client.mrr;
      await widget.svc.updateClientPlan(widget.client.id, _plan, mrr);
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
