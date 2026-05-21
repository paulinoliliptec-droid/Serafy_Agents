import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants.dart';
import '../../services/auth_service.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_form.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    try {
      await AuthService().signInWithEmailAndPassword(_email.text.trim(), _pass.text);
    } catch (e) {
      setState(() => _error = 'Credenciais inválidas');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.sidebarBg,
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Form(
                key: _form,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'agentOS Admin',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      alignment: Alignment.center,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.adminBadge,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'ADMIN',
                          style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _email,
                      decoration: const InputDecoration(labelText: 'Email'),
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) =>
                          (v == null || !v.contains('@')) ? 'Email inválido' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _pass,
                      decoration: const InputDecoration(labelText: 'Palavra-passe'),
                      obscureText: true,
                      validator: (v) =>
                          (v == null || v.length < 6) ? 'Mínimo 6 caracteres' : null,
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _loading ? null : _signIn,
                      child: _loading
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Entrar'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
