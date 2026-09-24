import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'auth_service.dart';

class FirebaseAdminAuthService implements AuthService {
  FirebaseAdminAuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  static const String _managedEmailDomain = 'users.learnable.app';

  String _emailFor(String username) {
    final value = username.trim().toLowerCase();
    if (value.contains('@')) return value;
    final safeUsername = value.replaceAll(RegExp(r'[^a-z0-9._-]'), '-');
    return '$safeUsername@$_managedEmailDomain';
  }

  @override
  Future<bool> login({
    required String username,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: _emailFor(username),
        password: password,
      );
      final user = credential.user;
      if (user == null) return false;

      final token = await user.getIdTokenResult(true);
      if (token.claims?['admin'] == true) return true;

      final directProfile = await _firestore
          .collection('users')
          .doc(user.uid)
          .get();
      var isAdmin =
          directProfile.data()?['role']?.toString().toLowerCase() == 'admin';
      if (!isAdmin) {
        final profiles = await _firestore
            .collection('users')
            .where('authUid', isEqualTo: user.uid)
            .limit(1)
            .get();
        isAdmin = profiles.docs.any(
          (doc) => doc.data()['role']?.toString().toLowerCase() == 'admin',
        );
      }
      if (isAdmin) {
        return true;
      }

      await _auth.signOut();
      return false;
    } on FirebaseAuthException {
      return false;
    } on FirebaseException {
      await _auth.signOut();
      return false;
    }
  }

  @override
  Future<void> logout() => _auth.signOut();
}
