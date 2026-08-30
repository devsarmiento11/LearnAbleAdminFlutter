abstract class AuthService {
  Future<bool> login({required String username, required String password});

  Future<void> logout();
}
