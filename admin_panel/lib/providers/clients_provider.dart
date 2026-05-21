import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/client.dart';

final clientsProvider = StreamProvider<List<Client>>((ref) {
  return FirebaseFirestore.instance
      .collection('tenants')
      .orderBy('created_at', descending: true)
      .snapshots()
      .map((s) => s.docs.map(Client.fromDoc).toList());
});

final selectedClientIdProvider = StateProvider<String?>((ref) => null);

final clientDetailProvider = StreamProvider.family<Client?, String>((ref, id) {
  return FirebaseFirestore.instance
      .collection('tenants')
      .doc(id)
      .snapshots()
      .map((s) => s.exists ? Client.fromDoc(s) : null);
});
