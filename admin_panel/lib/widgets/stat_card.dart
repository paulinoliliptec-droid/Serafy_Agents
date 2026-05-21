import 'package:flutter/material.dart';

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? iconColor;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? Theme.of(context).colorScheme.primary;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.12),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        )),
                const SizedBox(height: 4),
                Text(value,
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
