import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;

  Future<void> signInWithEmailAndPassword(String email, String password) =>
      _auth.signInWithEmailAndPassword(email: email, password: password);

  Future<void> signOut() => _auth.signOut();
}
