import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'admin_sidebar.dart';

class AdminScaffold extends StatelessWidget {
  final String title;
  final Widget child;
  final List<Widget>? actions;

  const AdminScaffold({
    super.key,
    required this.title,
    required this.child,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          const AdminSidebar(),
          Expanded(
            child: Column(
              children: [
                _TopBar(title: title, actions: actions),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: child,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final String title;
  final List<Widget>? actions;

  const _TopBar({required this.title, this.actions});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant, width: 1),
        ),
      ),
      child: Row(
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const Spacer(),
          if (actions != null) ...actions!,
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sair',
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
    );
  }
}
