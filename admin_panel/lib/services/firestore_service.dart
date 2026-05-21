import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/agent_config.dart';
import '../models/api_key.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;

  // ── Clients ──────────────────────────────────────────────────────────────

  Future<DocumentReference> createClient(Map<String, dynamic> data) =>
      _db.collection('tenants').add({
        ...data,
        'status': 'active',
        'mrr': 0.0,
        'created_at': FieldValue.serverTimestamp(),
      });

  Future<void> updateClient(String id, Map<String, dynamic> data) =>
      _db.collection('tenants').doc(id).update(data);

  Future<void> suspendClient(String id) =>
      _db.collection('tenants').doc(id).update({'status': 'suspended'});

  Future<void> activateClient(String id) =>
      _db.collection('tenants').doc(id).update({'status': 'active'});

  Future<void> updateClientPlan(String id, String plan, double mrr) =>
      _db.collection('tenants').doc(id).update({'plan': plan, 'mrr': mrr});

  // ── Agents ────────────────────────────────────────────────────────────────

  Stream<List<AgentConfig>> agentsStream(String clientId) => _db
      .collection('tenants')
      .doc(clientId)
      .collection('agents')
      .snapshots()
      .map((s) => s.docs.map(AgentConfig.fromDoc).toList());

  Future<void> updateAgent(
          String clientId, String agentName, Map<String, dynamic> data) =>
      _db
          .collection('tenants')
          .doc(clientId)
          .collection('agents')
          .doc(agentName)
          .set(data, SetOptions(merge: true));

  // ── Branding ──────────────────────────────────────────────────────────────

  Future<void> updateBranding(String clientId,
          {String? logoUrl, String? primaryColor, String? companyName}) =>
      _db.collection('tenants').doc(clientId).update({
        if (logoUrl != null) 'logo_url': logoUrl,
        if (primaryColor != null) 'primary_color': primaryColor,
        if (companyName != null) 'company_name': companyName,
      });

  // ── API Keys ──────────────────────────────────────────────────────────────

  Stream<List<ApiKey>> apiKeysStream(String clientId) => _db
      .collection('tenants')
      .doc(clientId)
      .collection('api_keys')
      .orderBy('created_at', descending: true)
      .snapshots()
      .map((s) => s.docs.map(ApiKey.fromDoc).toList());

  Future<String> createApiKey(String clientId, String name) async {
    final raw =
        'ak_${clientId.substring(0, 4)}_${DateTime.now().millisecondsSinceEpoch}';
    final preview = 'ak_...${raw.substring(raw.length - 4)}';
    await _db
        .collection('tenants')
        .doc(clientId)
        .collection('api_keys')
        .add({
      'name': name,
      'key_preview': preview,
      'revoked': false,
      'usage_count': 0,
      'created_at': FieldValue.serverTimestamp(),
    });
    return raw;
  }

  Future<void> revokeApiKey(String clientId, String keyId) => _db
      .collection('tenants')
      .doc(clientId)
      .collection('api_keys')
      .doc(keyId)
      .update({'revoked': true});
}
