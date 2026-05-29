import 'package:flutter_riverpod/flutter_riverpod.dart';

// Change this before deploying. Not persisted — requires re-entry on page refresh.
const kAdminPassword = 'Serafy@2024!';

final adminAuthProvider =
    StateNotifierProvider<AdminAuthNotifier, bool>((ref) => AdminAuthNotifier());

class AdminAuthNotifier extends StateNotifier<bool> {
  AdminAuthNotifier() : super(false);

  bool login(String password) {
    if (password == kAdminPassword) {
      state = true;
      return true;
    }
    return false;
  }

  void logout() => state = false;
}
