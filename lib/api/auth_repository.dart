// Auth flows: login / refresh / logout — maps to the /auth/* endpoints.
import 'api_client.dart';
import 'json_utils.dart';
import 'token_store.dart';

class AuthRepository {
  AuthRepository._();
  static final AuthRepository instance = AuthRepository._();

  final _api = ApiClient.instance;
  final _tokens = TokenStore.instance;

  /// POST /auth/login → { accessToken, refreshToken, user }
  ///
  /// NOTE: the login request field names aren't in the API sheet. We send the
  /// common `{ email, password }` shape; if your backend expects `username`,
  /// tell me and I'll switch it (single-line change here).
  Future<void> login({required String email, required String password}) async {
    final data = await _api.post('/auth/login', auth: false, body: {
      'email': email,
      'username': email, // sent both ways for safety until the contract is confirmed
      'password': password,
    });
    final map = asMap(data);
    final access = pickString(map, ['accessToken', 'access_token', 'token', 'jwt']);
    final refresh = pickString(map, ['refreshToken', 'refresh_token']);
    if (access.isEmpty) {
      throw ApiException(500, 'Login succeeded but no access token was returned');
    }
    final user = asMap(map?['user']) ?? map;
    final name = pickString(user, ['name', 'fullName', 'displayName', 'email', 'username'], fallback: email);
    await _tokens.save(accessToken: access, refreshToken: refresh.isEmpty ? null : refresh, userName: name);
  }

  /// POST /auth/logout — best-effort, always clears local tokens.
  Future<void> logout() async {
    try {
      await _api.post('/auth/logout');
    } catch (_) {/* ignore network errors on logout */}
    await _tokens.clear();
  }

  bool get isLoggedIn => _tokens.isLoggedIn;
  String? get userName => _tokens.userName;
}
