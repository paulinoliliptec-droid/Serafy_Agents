import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants.dart';
import '../../providers/clients_provider.dart';
import '../../widgets/admin_scaffold.dart';
import '../../widgets/country_flag.dart';

class ClientDetailScreen extends ConsumerWidget {
  final String clientId;
  const ClientDetailScreen({super.key, required this.clientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clientAsync = ref.watch(clientDetailProvider(clientId));

    return AdminScaffold(
      title: 'Detalhes do cliente',
      actions: [
        OutlinedButton.icon(
          onPressed: () => context.go('/clients/$clientId/agents'),
          icon: const Icon(Icons.smart_toy, size: 18),
          label: const Text('Agentes'),
        ),
      ],
      child: clientAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Text('Erro: $e'),
        data: (client) {
          if (client == null) return const Text('Cliente não encontrado');
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (client.logoUrl.isNotEmpty)
                        CircleAvatar(
                          backgroundImage: NetworkImage(client.logoUrl),
                          radius: 36,
                        )
                      else
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: Color(
                              int.parse(client.primaryColor.replaceFirst('#', '0xFF'))),
                          child: Text(
                            client.name.isNotEmpty ? client.name[0] : '?',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(client.name,
                                style: Theme.of(context).textTheme.headlineSmall),
                            if (client.companyName.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(client.companyName,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant)),
                            ],
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CountryFlag(countryCode: client.country),
                                    const SizedBox(width: 4),
                                    Text(kCplpCountries[client.country]?.$1 ??
                                        client.country),
                                  ],
                                ),
                                Chip(
                                    label: Text(client.plan,
                                        style: const TextStyle(fontSize: 12)),
                                    padding: EdgeInsets.zero),
                                Chip(
                                  label: Text(
                                      client.isActive ? 'Activo' : 'Suspenso',
                                      style: const TextStyle(fontSize: 12)),
                                  backgroundColor: client.isActive
                                      ? Colors.green.withOpacity(0.1)
                                      : Colors.red.withOpacity(0.1),
                                  padding: EdgeInsets.zero,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('MRR',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant)),
                          Text('\$${client.mrr.toStringAsFixed(0)}',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _ActionCard(
                    icon: Icons.smart_toy,
                    label: 'Agentes',
                    onTap: () => context.go('/clients/$clientId/agents'),
                  ),
                  _ActionCard(
                    icon: Icons.palette,
                    label: 'Branding',
                    onTap: () => context.go(AppRoutes.branding),
                  ),
                  _ActionCard(
                    icon: Icons.vpn_key,
                    label: 'API Keys',
                    onTap: () => context.go(AppRoutes.apiKeys),
                  ),
                  _ActionCard(
                    icon: Icons.receipt_long,
                    label: 'Faturação',
                    onTap: () => context.go(AppRoutes.billing),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 32,
                  color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 8),
              Text(label, style: Theme.of(context).textTheme.labelLarge),
            ],
          ),
        ),
      ),
    );
  }
}
