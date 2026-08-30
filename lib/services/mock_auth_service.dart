import 'auth_service.dart';

class MockAuthService implements AuthService {
  @override
  Future<bool> login({
    required String username,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));

    return username == 'admin' && password == 'admin123';
  }

  @override
  Future<void> logout() async {}
}
