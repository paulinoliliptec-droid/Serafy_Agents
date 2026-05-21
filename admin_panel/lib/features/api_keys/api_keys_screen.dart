import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/api_key.dart';
import '../../providers/clients_provider.dart';
import '../../services/firestore_service.dart';
import '../../widgets/admin_scaffold.dart';

final _selectedClientProvider = StateProvider<String?>((ref) => null);

final _apiKeysProvider =
    StreamProvider.family<List<ApiKey>, String>((ref, clientId) {
  return FirestoreService().apiKeysStream(clientId);
});

class ApiKeysScreen extends ConsumerWidget {
  const ApiKeysScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientsAsync = ref.watch(clientsProvider);
    final selectedId = ref.watch(_selectedClientProvider);

    return AdminScaffold(
      title: 'API Keys',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          clientsAsync.when(
            loading: () => const CircularProgressIndicator(),
            error: (e, _) => Text('Erro: $e'),
            data: (clients) => DropdownButtonFormField<String>(
              value: selectedId,
              decoration: const InputDecoration(labelText: 'Cliente'),
              items: clients
                  .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
                  .toList(),
              onChanged: (v) =>
                  ref.read(_selectedClientProvider.notifier).state = v,
            ),
          ),
          const SizedBox(height: 24),
          if (selectedId != null)
            _KeysPanel(clientId: selectedId),
        ],
      ),
    );
  }
}

class _KeysPanel extends ConsumerWidget {
  final String clientId;
  const _KeysPanel({required this.clientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final keysAsync = ref.watch(_apiKeysProvider(clientId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Chaves API',
                style: Theme.of(context).textTheme.titleMedium),
            const Spacer(),
            FilledButton.icon(
              onPressed: () => _showCreateDialog(context, clientId),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Nova chave'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        keysAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('Erro: $e'),
          data: (keys) => keys.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('Nenhuma chave API'),
                  ),
                )
              : Card(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      headingRowColor: WidgetStateProperty.all(
                          Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest),
                      columns: const [
                        DataColumn(label: Text('Nome')),
                        DataColumn(label: Text('Chave')),
                        DataColumn(label: Text('Estado')),
                        DataColumn(label: Text('Usos')),
                        DataColumn(label: Text('Último uso')),
                        DataColumn(label: Text('Acções')),
                      ],
                      rows: keys
                          .map((k) => _keyRow(context, k, clientId))
                          .toList(),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  DataRow _keyRow(BuildContext context, ApiKey key, String clientId) {
    return DataRow(
      cells: [
        DataCell(Text(key.name)),
        DataCell(Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(key.keyPreview,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 13)),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.copy, size: 16),
              tooltip: 'Copiar',
              onPressed: () =>
                  Clipboard.setData(ClipboardData(text: key.keyPreview)),
            ),
          ],
        )),
        DataCell(
          key.revoked
              ? const Chip(
                  label: Text('Revogada', style: TextStyle(fontSize: 12)),
                  backgroundColor: Color(0x22EF4444),
                  padding: EdgeInsets.zero)
              : const Chip(
                  label: Text('Activa', style: TextStyle(fontSize: 12)),
                  backgroundColor: Color(0x2222C55E),
                  padding: EdgeInsets.zero),
        ),
        DataCell(Text('${key.usageCount}')),
        DataCell(Text(key.lastUsed != null
            ? _fmt(key.lastUsed!)
            : 'Nunca')),
        DataCell(key.revoked
            ? const SizedBox.shrink()
            : IconButton(
                icon: const Icon(Icons.block, size: 18, color: Colors.red),
                tooltip: 'Revogar',
                onPressed: () =>
                    FirestoreService().revokeApiKey(clientId, key.id),
              )),
      ],
    );
  }

  String _fmt(DateTime dt) =>
      '${dt.day.toString().padLeft(2,'0')}/${dt.month.toString().padLeft(2,'0')} '
      '${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';

  void _showCreateDialog(BuildContext context, String clientId) {
    showDialog(
      context: context,
      builder: (_) => _CreateKeyDialog(clientId: clientId),
    );
  }
}

class _CreateKeyDialog extends StatefulWidget {
  final String clientId;
  const _CreateKeyDialog({required this.clientId});

  @override
  State<_CreateKeyDialog> createState() => _CreateKeyDialogState();
}

class _CreateKeyDialogState extends State<_CreateKeyDialog> {
  final _nameCtrl = TextEditingController();
  bool _saving = false;
  String? _generatedKey;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nova API Key'),
      content: _generatedKey != null
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Guarde esta chave agora — não será mostrada novamente.',
                  style: TextStyle(color: Colors.orange),
                ),
                const SizedBox(height: 12),
                SelectableText(
                  _generatedKey!,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                ),
              ],
            )
          : TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Nome da chave'),
              autofocus: true,
            ),
      actions: _generatedKey != null
          ? [
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fechar'),
              ),
            ]
          : [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar')),
              FilledButton(
                onPressed: _saving ? null : _create,
                child: const Text('Gerar'),
              ),
            ],
    );
  }

  Future<void> _create() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    try {
      final key = await FirestoreService()
          .createApiKey(widget.clientId, _nameCtrl.text.trim());
      setState(() => _generatedKey = key);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
