import 'package:cloud_firestore/cloud_firestore.dart';

class AgentConfig {
  final String name;
  final bool enabled;
  final String prompt;
  final bool kiesse;

  const AgentConfig({
    required this.name,
    required this.enabled,
    required this.prompt,
    required this.kiesse,
  });

  factory AgentConfig.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};
    return AgentConfig(
      name: doc.id,
      enabled: d['enabled'] ?? true,
      prompt: d['prompt'] ?? '',
      kiesse: d['kiesse_enabled'] ?? false,
    );
  }

  AgentConfig copyWith({bool? enabled, String? prompt, bool? kiesse}) => AgentConfig(
        name: name,
        enabled: enabled ?? this.enabled,
        prompt: prompt ?? this.prompt,
        kiesse: kiesse ?? this.kiesse,
      );

  Map<String, dynamic> toMap() => {
        'enabled': enabled,
        'prompt': prompt,
        'kiesse_enabled': kiesse,
      };
}
