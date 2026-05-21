import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

final isAdminProvider = FutureProvider<bool>((ref) async {
  final userAsync = ref.watch(authStateProvider);
  final user = userAsync.asData?.value;
  if (user == null) return false;

  final doc = await FirebaseFirestore.instance.collection('config').doc('admin').get();
  final data = doc.data();
  if (data == null) return false;

  final uids = (data['uids'] as List<dynamic>? ?? []).cast<String>();
  return uids.contains(user.uid);
});
