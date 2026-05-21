import 'package:cloud_firestore/cloud_firestore.dart';

class ApiKey {
  final String id;
  final String name;
  final String keyPreview;  // "ak_...xxxx" — last 4 chars only
  final bool revoked;
  final int usageCount;
  final DateTime createdAt;
  final DateTime? lastUsed;

  const ApiKey({
    required this.id,
    required this.name,
    required this.keyPreview,
    required this.revoked,
    required this.usageCount,
    required this.createdAt,
    this.lastUsed,
  });

  factory ApiKey.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ApiKey(
      id: doc.id,
      name: d['name'] ?? 'API Key',
      keyPreview: d['key_preview'] ?? 'ak_****',
      revoked: d['revoked'] ?? false,
      usageCount: d['usage_count'] ?? 0,
      createdAt: (d['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastUsed: (d['last_used'] as Timestamp?)?.toDate(),
    );
  }
}
