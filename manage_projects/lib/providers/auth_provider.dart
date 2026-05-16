import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../data/grad_hub_api.dart';

const _tokenKey = 'gh_access_token';

class AuthProvider extends ChangeNotifier {
  AuthProvider(this.api, this.dio);

  final GradHubApi api;
  final Dio dio;

  final FlutterSecureStorage _store = const FlutterSecureStorage();

  Map<String, dynamic>? _snapshot;
  bool _ready = false;
  int _sessionRevision = 0;

  bool get isReady => _ready;
  
  /// يزداد عند كل تحديث لبيانات الجلسة (`me`) — لتحديث تبويبات مثل دعوات الإشراف بعد إرسال طلب.
  int get sessionRevision => _sessionRevision;

  void _bumpSessionRevision() {
    _sessionRevision++;
  }
  bool get isAuthenticated => dio.options.headers.containsKey('Authorization');
  Map<String, dynamic>? get snapshot => _snapshot;

  String? get role =>
      (_snapshot != null ? _snapshot!['role'] : null)?.toString();

  Map<String, dynamic>? get user {
    final raw = _snapshot?['user'];
    if (raw is Map<String, dynamic>) {
      return raw;
    }
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }
    return null;
  }

  bool get studentHasProject =>
      studentProjectId != null && studentProjectId!.isNotEmpty;

  String? get studentUserId => user?['id']?.toString();

  List<String> get blockedProjectIds {
    final raw = user?['blockedProjectIds'];
    if (raw is! List) {
      return [];
    }
    return raw.map((e) => e.toString()).toList();
  }

  bool projectIsBlocked(String projectId) =>
      blockedProjectIds.contains(projectId);

  bool get canInviteSupervisors =>
      user?['canInviteSupervisors'] == true;

  bool get studentCanRequestJoinToSupervisedProjects {
    final v = user?['canRequestJoinToSupervisedProjects'];
    if (v == true) {
      return true;
    }
    if (v == false) {
      return false;
    }
    return !studentHasProject;
  }

  String? get studentProjectId {
    final p = user?['project'];
    if (p == null) {
      return null;
    }
    final s = p.toString();
    if (s.isEmpty || s == 'null') {
      return null;
    }
    return s;
  }

  Future<void> bootstrap() async {
    try {
      final tok = await _store.read(key: _tokenKey);
      if (tok != null && tok.isNotEmpty) {
        dio.options.headers['Authorization'] = 'Bearer $tok';
        _snapshot = await api.me();
        _bumpSessionRevision();
      }
    } catch (_) {
      await logoutSilent();
    }
    _ready = true;
    notifyListeners();
  }

  Future<void> _saveToken(String t) async {
    await _store.write(key: _tokenKey, value: t);
    dio.options.headers['Authorization'] = 'Bearer $t';
  }

  Future<void> loginAdmin(String email, String pw) =>
      _login(() => api.adminLogin(email, pw));

  Future<void> loginDoctor(String email, String pw) =>
      _login(() => api.doctorLogin(email, pw));

  Future<void> loginStudent(String uni, String pw) =>
      _login(() => api.studentLogin(uni, pw));

  Future<void> persistFromRegistration(Map<String, dynamic> resp) =>
      _applyAuthResponse(resp);

  Future<void> _login(Future<Map<String, dynamic>> Function() fn) async {
    final resp = await fn();
    await _applyAuthResponse(resp);
  }

  Future<void> _applyAuthResponse(Map<String, dynamic> resp) async {
    final t = resp['accessToken'];
    if (t is! String || t.isEmpty) {
      throw StateError('الخادوم لم يعيد رمز الوصول.');
    }
    await _saveToken(t);
    _snapshot = await api.me();
    _bumpSessionRevision();
    notifyListeners();
  }

  Future<void> refreshMe() async {
    if (!isAuthenticated) {
      return;
    }
    _snapshot = await api.me();
    _bumpSessionRevision();
    notifyListeners();
  }

  Future<void> logoutSilent() async {
    await _store.delete(key: _tokenKey);
    dio.options.headers.remove('Authorization');
    _snapshot = null;
    _bumpSessionRevision();
  }

  Future<void> logout() async {
    await logoutSilent();
    notifyListeners();
  }
}
