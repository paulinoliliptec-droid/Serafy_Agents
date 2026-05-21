import 'package:cloud_firestore/cloud_firestore.dart';

class Client {
  final String id;
  final String name;
  final String country;
  final String plan;
  final String status;
  final double mrr;
  final String primaryColor;
  final String logoUrl;
  final String companyName;
  final DateTime createdAt;

  const Client({
    required this.id,
    required this.name,
    required this.country,
    required this.plan,
    required this.status,
    required this.mrr,
    required this.primaryColor,
    required this.logoUrl,
    required this.companyName,
    required this.createdAt,
  });

  factory Client.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Client(
      id: doc.id,
      name: d['name'] ?? '',
      country: d['country'] ?? 'AO',
      plan: d['plan'] ?? 'free',
      status: d['status'] ?? 'active',
      mrr: (d['mrr'] ?? 0.0).toDouble(),
      primaryColor: d['primary_color'] ?? '#3B82F6',
      logoUrl: d['logo_url'] ?? '',
      companyName: d['company_name'] ?? '',
      createdAt: (d['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'country': country,
        'plan': plan,
        'status': status,
        'mrr': mrr,
        'primary_color': primaryColor,
        'logo_url': logoUrl,
        'company_name': companyName,
      };

  bool get isActive => status == 'active';
}
