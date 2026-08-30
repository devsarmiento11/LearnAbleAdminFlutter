import 'auth_service.dart';

/// Migration-compatible login retained from the former web admin.
class FirebaseAdminAuthService implements AuthService {
  const FirebaseAdminAuthService();

  @override
  Future<bool> login({
    required String username,
    required String password,
  }) async {
    return username == 'admin' && password == 'admin123';
  }

  @override
  Future<void> logout() async {}
}
