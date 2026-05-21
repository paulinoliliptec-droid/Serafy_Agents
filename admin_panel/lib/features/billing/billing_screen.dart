import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/billing_record.dart';
import '../../providers/billing_provider.dart';
import '../../widgets/admin_scaffold.dart';

// Web-only download helper
import 'billing_download_stub.dart'
    if (dart.library.html) 'billing_download_web.dart';

class BillingScreen extends ConsumerWidget {
  const BillingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(billingMonthProvider);
    final recordsAsync = ref.watch(billingRecordsProvider(month));

    return AdminScaffold(
      title: 'Faturação',
      actions: [
        recordsAsync.whenOrNull(
          data: (records) => OutlinedButton.icon(
            onPressed: () => _exportCsv(records, month),
            icon: const Icon(Icons.download, size: 18),
            label: const Text('Exportar CSV'),
          ),
        ) ?? const SizedBox.shrink(),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Month picker
          Row(
            children: [
              Text('Período:', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(width: 12),
              _MonthSelector(selected: month, onChanged: (m) {
                ref.read(billingMonthProvider.notifier).state = m;
              }),
            ],
          ),
          const SizedBox(height: 24),
          recordsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Erro: $e'),
            data: (records) => _BillingTable(records: records, month: month),
          ),
        ],
      ),
    );
  }

  void _exportCsv(List<BillingRecord> records, String month) {
    final rows = [
      BillingRecord.csvHeaders,
      ...records.map((r) => r.toCsvRow()),
    ];
    final csv = const ListToCsvConverter().convert(rows);
    downloadCsv(csv, 'billing_$month.csv');
  }
}

class _MonthSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _MonthSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final months = List.generate(12, (i) {
      final dt = DateTime(now.year, now.month - i);
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}';
    });

    return DropdownButton<String>(
      value: selected,
      items: months
          .map((m) => DropdownMenuItem(value: m, child: Text(m)))
          .toList(),
      onChanged: (v) { if (v != null) onChanged(v); },
    );
  }
}

class _BillingTable extends StatelessWidget {
  final List<BillingRecord> records;
  final String month;

  const _BillingTable({required this.records, required this.month});

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: Text('Sem registos para $month'),
        ),
      );
    }

    final totalMrr = records.fold(0.0, (s, r) => s + r.mrr);
    final totalCost = records.fold(0.0, (s, r) => s + r.llmCost);
    final totalConversations = records.fold(0, (s, r) => s + r.conversations);

    return Column(
      children: [
        // Summary row
        Row(
          children: [
            _SummaryCard(label: 'MRR Total', value: '\$${totalMrr.toStringAsFixed(0)}', color: Colors.green),
            const SizedBox(width: 12),
            _SummaryCard(label: 'Custo LLM', value: '\$${totalCost.toStringAsFixed(2)}', color: Colors.orange),
            const SizedBox(width: 12),
            _SummaryCard(label: 'Conversas', value: '$totalConversations', color: Colors.blue),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(
                  Theme.of(context).colorScheme.surfaceContainerHighest),
              columns: const [
                DataColumn(label: Text('Cliente')),
                DataColumn(label: Text('MRR'), numeric: true),
                DataColumn(label: Text('Conversas'), numeric: true),
                DataColumn(label: Text('Custo LLM'), numeric: true),
                DataColumn(label: Text('Margem'), numeric: true),
              ],
              rows: records.map((r) {
                final margin = r.mrr > 0
                    ? ((r.mrr - r.llmCost) / r.mrr * 100)
                    : 0.0;
                return DataRow(cells: [
                  DataCell(Text(r.tenantName.isEmpty ? r.tenantId : r.tenantName)),
                  DataCell(Text('\$${r.mrr.toStringAsFixed(0)}')),
                  DataCell(Text('${r.conversations}')),
                  DataCell(Text('\$${r.llmCost.toStringAsFixed(2)}')),
                  DataCell(Text(
                    '${margin.toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: margin >= 60
                          ? Colors.green
                          : margin >= 30
                              ? Colors.orange
                              : Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  )),
                ]);
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
              const SizedBox(height: 4),
              Text(value,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: color, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}
