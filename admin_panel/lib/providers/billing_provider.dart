import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/billing_record.dart';

final billingMonthProvider = StateProvider<String>((ref) {
  final now = DateTime.now();
  return '${now.year}-${now.month.toString().padLeft(2, '0')}';
});

final billingRecordsProvider =
    FutureProvider.family<List<BillingRecord>, String>((ref, yearMonth) async {
  final tenantsSnap =
      await FirebaseFirestore.instance.collection('tenants').get();

  final records = <BillingRecord>[];
  for (final tenantDoc in tenantsSnap.docs) {
    final tenantName =
        (tenantDoc.data() as Map<String, dynamic>)['name'] as String? ?? '';
    final billingDoc = await tenantDoc.reference
        .collection('billing')
        .doc(yearMonth)
        .get();
    if (billingDoc.exists) {
      records.add(BillingRecord.fromDoc(billingDoc, tenantName: tenantName));
    }
  }

  records.sort((a, b) => b.mrr.compareTo(a.mrr));
  return records;
});
