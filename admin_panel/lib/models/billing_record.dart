import 'package:cloud_firestore/cloud_firestore.dart';

class BillingRecord {
  final String tenantId;
  final String tenantName;
  final String yearMonth;   // "2025-05"
  final double mrr;
  final int conversations;
  final double llmCost;

  const BillingRecord({
    required this.tenantId,
    required this.tenantName,
    required this.yearMonth,
    required this.mrr,
    required this.conversations,
    required this.llmCost,
  });

  factory BillingRecord.fromDoc(DocumentSnapshot doc, {String tenantName = ''}) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    return BillingRecord(
      tenantId: doc.reference.parent.parent?.id ?? '',
      tenantName: tenantName,
      yearMonth: d['month'] ?? doc.id,
      mrr: (d['mrr'] ?? 0.0).toDouble(),
      conversations: (d['conversations'] ?? 0) as int,
      llmCost: (d['llm_cost'] ?? 0.0).toDouble(),
    );
  }

  List<String> toCsvRow() => [
        tenantId,
        tenantName,
        yearMonth,
        mrr.toStringAsFixed(2),
        conversations.toString(),
        llmCost.toStringAsFixed(4),
      ];

  static List<String> get csvHeaders =>
      ['tenant_id', 'tenant_name', 'month', 'mrr_usd', 'conversations', 'llm_cost_usd'];
}
