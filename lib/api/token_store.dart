// Persists the auth tokens (access + refresh) across launches.
import 'package:shared_preferences/shared_preferences.dart';

class TokenStore {
  TokenStore._();
  static final TokenStore instance = TokenStore._();

  static const _kAccess = 'auth.accessToken';
  static const _kRefresh = 'auth.refreshToken';
  static const _kUser = 'auth.userName';

  String? _access;
  String? _refresh;
  String? _userName;

  String? get accessToken => _access;
  String? get refreshToken => _refresh;
  String? get userName => _userName;
  bool get isLoggedIn => (_access ?? '').isNotEmpty;

  Future<void> load() async {
    final p = await SharedPreferences.getInstance();
    _access = p.getString(_kAccess);
    _refresh = p.getString(_kRefresh);
    _userName = p.getString(_kUser);
  }

  Future<void> save({required String accessToken, String? refreshToken, String? userName}) async {
    _access = accessToken;
    if (refreshToken != null) _refresh = refreshToken;
    if (userName != null) _userName = userName;
    final p = await SharedPreferences.getInstance();
    await p.setString(_kAccess, accessToken);
    if (refreshToken != null) await p.setString(_kRefresh, refreshToken);
    if (userName != null) await p.setString(_kUser, userName);
  }

  Future<void> updateAccess(String accessToken) async {
    _access = accessToken;
    final p = await SharedPreferences.getInstance();
    await p.setString(_kAccess, accessToken);
  }

  Future<void> clear() async {
    _access = null;
    _refresh = null;
    _userName = null;
    final p = await SharedPreferences.getInstance();
    await p.remove(_kAccess);
    await p.remove(_kRefresh);
    await p.remove(_kUser);
  }
}
