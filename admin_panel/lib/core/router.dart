import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/login_screen.dart';
import '../features/auth/unauthorized_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/clients/clients_screen.dart';
import '../features/clients/client_detail_screen.dart';
import '../features/agents/agents_screen.dart';
import '../features/branding/branding_screen.dart';
import '../features/api_keys/api_keys_screen.dart';
import '../features/billing/billing_screen.dart';
import '../providers/auth_provider.dart';
import 'constants.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = _RouterNotifier(ref);
  return GoRouter(
    refreshListenable: notifier,
    initialLocation: AppRoutes.dashboard,
    redirect: notifier.redirect,
    routes: [
      GoRoute(path: AppRoutes.login, builder: (_, __) => const LoginScreen()),
      GoRoute(path: AppRoutes.unauthorized, builder: (_, __) => const UnauthorizedScreen()),
      GoRoute(path: AppRoutes.dashboard, builder: (_, __) => const DashboardScreen()),
      GoRoute(path: AppRoutes.clients, builder: (_, __) => const ClientsScreen()),
      GoRoute(
        path: AppRoutes.clientDetail,
        builder: (_, state) => ClientDetailScreen(clientId: state.pathParameters['id']!),
        routes: [
          GoRoute(
            path: 'agents',
            builder: (_, state) => AgentsScreen(clientId: state.pathParameters['id']!),
          ),
        ],
      ),
      GoRoute(path: AppRoutes.branding, builder: (_, __) => const BrandingScreen()),
      GoRoute(path: AppRoutes.apiKeys, builder: (_, __) => const ApiKeysScreen()),
      GoRoute(path: AppRoutes.billing, builder: (_, __) => const BillingScreen()),
    ],
  );
});

class _RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  _RouterNotifier(this._ref) {
    _ref.listen(authStateProvider, (_, __) => notifyListeners());
    _ref.listen(isAdminProvider, (_, __) => notifyListeners());
  }

  String? redirect(BuildContext context, GoRouterState state) {
    final authState = _ref.read(authStateProvider);
    final isAdmin = _ref.read(isAdminProvider).asData?.value ?? false;
    final isLoggedIn = authState.asData?.value != null;
    final isLoading = authState.isLoading || _ref.read(isAdminProvider).isLoading;
    final loc = state.matchedLocation;

    if (isLoading) return null;
    if (!isLoggedIn) return loc == AppRoutes.login ? null : AppRoutes.login;
    if (!isAdmin) return loc == AppRoutes.unauthorized ? null : AppRoutes.unauthorized;
    if (loc == AppRoutes.login) return AppRoutes.dashboard;
    return null;
  }
}
