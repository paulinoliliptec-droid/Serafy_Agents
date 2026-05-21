import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class UnauthorizedScreen extends StatelessWidget {
  const UnauthorizedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lock_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Acesso negado',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            const Text('A sua conta não tem permissões de administrador.'),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => FirebaseAuth.instance.signOut(),
              icon: const Icon(Icons.logout),
              label: const Text('Sair'),
            ),
          ],
        ),
      ),
    );
  }
}
