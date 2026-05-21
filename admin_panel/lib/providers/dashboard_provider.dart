import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/client.dart';

class DashboardStats {
  final double totalMrr;
  final int totalClients;
  final int activeClients;
  final Map<String, int> clientsByCountry;
  final double totalLlmCost;
  final int totalConversations;

  const DashboardStats({
    required this.totalMrr,
    required this.totalClients,
    required this.activeClients,
    required this.clientsByCountry,
    required this.totalLlmCost,
    required this.totalConversations,
  });
}

final dashboardStatsProvider = FutureProvider<DashboardStats>((ref) async {
  final tenantsSnap =
      await FirebaseFirestore.instance.collection('tenants').get();
  final clients = tenantsSnap.docs.map(Client.fromDoc).toList();

  final countryMap = <String, int>{};
  double mrr = 0;
  int active = 0;
  for (final c in clients) {
    mrr += c.mrr;
    if (c.isActive) active++;
    countryMap[c.country] = (countryMap[c.country] ?? 0) + 1;
  }

  // Aggregate last 30-day billing from billing sub-collections
  double llmCost = 0;
  int conversations = 0;
  final now = DateTime.now();
  final thisMonth = '${now.year}-${now.month.toString().padLeft(2, '0')}';
  for (final doc in tenantsSnap.docs) {
    final billingSnap = await doc.reference
        .collection('billing')
        .doc(thisMonth)
        .get();
    if (billingSnap.exists) {
      final d = billingSnap.data() as Map<String, dynamic>;
      llmCost += (d['llm_cost'] ?? 0.0).toDouble();
      conversations += (d['conversations'] ?? 0) as int;
    }
  }

  return DashboardStats(
    totalMrr: mrr,
    totalClients: clients.length,
    activeClients: active,
    clientsByCountry: countryMap,
    totalLlmCost: llmCost,
    totalConversations: conversations,
  );
});

class ConversationPoint {
  final DateTime date;
  final int count;
  const ConversationPoint({required this.date, required this.count});
}

final conversationHistoryProvider =
    FutureProvider<List<ConversationPoint>>((ref) async {
  final snap = await FirebaseFirestore.instance
      .collection('analytics')
      .doc('conversations_daily')
      .get();

  if (!snap.exists) return [];
  final data = snap.data() as Map<String, dynamic>;
  final points = <ConversationPoint>[];
  data.forEach((k, v) {
    try {
      final date = DateTime.parse(k);
      points.add(ConversationPoint(date: date, count: (v as num).toInt()));
    } catch (_) {}
  });
  points.sort((a, b) => a.date.compareTo(b.date));
  return points.length > 30 ? points.sublist(points.length - 30) : points;
});
