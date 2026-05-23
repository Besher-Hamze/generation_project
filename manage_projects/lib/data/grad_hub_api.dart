import 'package:dio/dio.dart';

/// عميل نوعي لمسارات Nest تحت `/api`.
class GradHubApi {
  GradHubApi(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> adminLogin(String email, String password) =>
      _post('/auth/admin/login', {'email': email, 'password': password});

  Future<Map<String, dynamic>> doctorLogin(String email, String password) =>
      _post('/auth/doctor/login', {'email': email, 'password': password});

  Future<Map<String, dynamic>> studentLogin(
    String uniNumber,
    String password,
  ) =>
      _post('/auth/student/login', {
        'uniNumber': uniNumber,
        'password': password,
      });

  Future<Map<String, dynamic>> studentRegister(Map<String, dynamic> body) =>
      _post('/auth/student/register', body);

  Future<Map<String, dynamic>> me() async {
    final r = await _dio.get<Map<String, dynamic>>('/auth/me');
    return r.data!;
  }

  Future<List<dynamic>> publicDepartments() => _getList('/public/departments');

  Future<List<dynamic>> publicRegistrationOrders() =>
      _getList('/public/registration-orders');

  Future<List<dynamic>> publicProjects() => _getList('/public/projects');

  Future<List<dynamic>> getList(String path) => _getList(path);

  Future<Map<String, dynamic>> getProject(String id) async {
    final r = await _dio.get<Map<String, dynamic>>('/projects/$id');
    return r.data!;
  }

  Future<Map<String, dynamic>> createStudentProject(
    Map<String, dynamic> body,
  ) async {
    final r = await _dio.post<Map<String, dynamic>>('/projects/mine', data: body);
    return r.data!;
  }

  /// منشئ المشروع: تعديل العنوان والوصف والعام (حسب سياسات الخادوم).
  Future<Map<String, dynamic>> patchMyProjectContent(
    String projectId, {
    required String title,
    required String description,
    required String academicYear,
  }) async {
    final r = await _dio.patch<Map<String, dynamic>>(
      '/projects/mine/$projectId',
      data: {
        'title': title,
        'description': description,
        'academicYear': academicYear,
      },
    );
    return r.data!;
  }

  /// حذف المشروع الذي أنشأته وحدك (بحسب اشتراطات الخادوم).
  Future<void> deleteMyProject(String projectId) async {
    await _dio.delete<void>('/projects/mine/$projectId');
  }

  /// قائد فريق: فتح/إغلاق قبول انضمام طلاب؛ تعديل السقف (مثلاً ٢).
  Future<Map<String, dynamic>> patchMyProjectTeamEnrollment(
    String projectId, {
    bool? enrollmentOpen,
    int? maxTeamMembers,
  }) async {
    final map = <String, dynamic>{};
    if (enrollmentOpen != null) {
      map['enrollmentOpen'] = enrollmentOpen;
    }
    if (maxTeamMembers != null) {
      map['maxTeamMembers'] = maxTeamMembers;
    }
    final r = await _dio.patch<Map<String, dynamic>>(
      '/projects/mine/$projectId/team-enrollment',
      data: map,
    );
    return r.data!;
  }

  Future<void> joinRequestCreate(String projectId) async {
    await _dio.post<void>('/join-requests', data: {'projectId': projectId});
  }

  Future<List<dynamic>> joinOutgoing() =>
      _getList('/join-requests/me/outgoing');

  Future<List<dynamic>> doctorJoinPending() =>
      _getList('/join-requests/doctor/pending');

  Future<Map<String, dynamic>> doctorJoinApprove(String id) async {
    final r = await _dio.patch<Map<String, dynamic>>(
      '/join-requests/doctor/$id/approve',
    );
    return Map<String, dynamic>.from(r.data ?? {});
  }

  Future<Map<String, dynamic>> doctorJoinReject(String id) async {
    final r = await _dio.patch<Map<String, dynamic>>(
      '/join-requests/doctor/$id/reject',
    );
    return Map<String, dynamic>.from(r.data ?? {});
  }

  Future<List<dynamic>> sessionsMe() => _getList('/sessions/me');

  /// إدارة: تعديل مشروع بما في ذلك ربط اللجنة (`committees`: معرف أو null لإلغاء الربط).
  Future<Map<String, dynamic>> adminPatchProject(
    String projectId,
    Map<String, dynamic> patch,
  ) async {
    final r = await _dio.patch<Map<String, dynamic>>(
      '/projects/$projectId',
      data: patch,
    );
    return r.data!;
  }

  /// دكتور: جلسة لمشروع يشرف عليه.
  Future<Map<String, dynamic>> createSession({
    required String projectId,
    num? mark,
    String? notes,
    int? sessionNum,
    String? title,
    String? heldAtIso,
    String? doctorId,
  }) async {
    final body = <String, dynamic>{
      'project': projectId,
      if (mark != null) 'mark': mark,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
      if (sessionNum != null) 'sessionNum': sessionNum,
      if (title != null && title.isNotEmpty) 'title': title,
      if (heldAtIso != null && heldAtIso.isNotEmpty) 'heldAt': heldAtIso,
      if (doctorId != null && doctorId.isNotEmpty) 'doctor': doctorId,
    };
    final r = await _dio.post<Map<String, dynamic>>('/sessions', data: body);
    return r.data!;
  }

  /// إنشاء لجنة (أسماؤها المعروضة للطلاب كـ«لجنة A» مثلاً).
  Future<Map<String, dynamic>> adminCreateCommittee({
    required String label,
    String? presidentDoctorId,
  }) async {
    final body = <String, dynamic>{
      'label': label.trim(),
      if (presidentDoctorId != null && presidentDoctorId.trim().isNotEmpty)
        'president': presidentDoctorId.trim(),
    };
    final r = await _dio.post<Map<String, dynamic>>('/committees', data: body);
    return r.data!;
  }

  Future<Map<String, dynamic>> adminLinkDoctorToCommittee({
    required String committeeId,
    required String doctorId,
    required bool isPresident,
  }) async {
    final r = await _dio.post<Map<String, dynamic>>(
      '/committee-doctors',
      data: {
        'committees': committeeId,
        'doctor': doctorId,
        'isPresident': isPresident,
      },
    );
    return r.data!;
  }

  Future<Map<String, dynamic>> adminPatchCommitteePresident({
    required String committeeId,
    String? presidentDoctorId,
  }) async {
    final patch = presidentDoctorId == null || presidentDoctorId.trim().isEmpty
        ? <String, dynamic>{'president': null}
        : <String, dynamic>{'president': presidentDoctorId.trim()};
    final r = await _dio.patch<Map<String, dynamic>>(
      '/committees/$committeeId',
      data: patch,
    );
    return r.data!;
  }

  Future<void> doctorChangePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _dio.patch<void>(
      '/auth/doctor/password',
      data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      },
    );
  }

  Future<List<dynamic>> publicDoctors() => _getList('/public/doctors');

  Future<void> peerTeamJoinCreate(String projectId) async {
    await _dio.post<void>(
      '/peer-team-requests',
      data: {'projectId': projectId},
    );
  }

  Future<List<dynamic>> peerTeamOutgoing() =>
      _getList('/peer-team-requests/me/outgoing');

  Future<List<dynamic>> peerTeamIncoming() =>
      _getList('/peer-team-requests/me/incoming');

  Future<Map<String, dynamic>> peerOwnerApprove(String id) async {
    final r = await _dio.patch<Map<String, dynamic>>(
      '/peer-team-requests/$id/owner-approve',
    );
    return Map<String, dynamic>.from(r.data ?? {});
  }

  Future<Map<String, dynamic>> peerOwnerReject(String id) async {
    final r = await _dio.patch<Map<String, dynamic>>(
      '/peer-team-requests/$id/owner-reject',
    );
    return Map<String, dynamic>.from(r.data ?? {});
  }

  Future<List<dynamic>> sendSupervisionInvites({
    required String projectId,
    required List<String> doctorIds,
  }) async {
    final r = await _dio.post<dynamic>(
      '/supervision-invitations',
      data: {'projectId': projectId, 'doctorIds': doctorIds},
    );
    final d = r.data;
    if (d is List) {
      return d;
    }
    throw StateError('استجابة غير متوقعة عند إرسال دعوات الإشراف');
  }

  Future<List<dynamic>> supervisionOutgoing() =>
      _getList('/supervision-invitations/me/outgoing');

  Future<List<dynamic>> supervisionDoctorPending() =>
      _getList('/supervision-invitations/doctor/pending');

  Future<Map<String, dynamic>> supervisionAccept(String id) async {
    final r = await _dio.patch<Map<String, dynamic>>(
      '/supervision-invitations/doctor/$id/accept',
    );
    return Map<String, dynamic>.from(r.data ?? {});
  }

  Future<Map<String, dynamic>> supervisionReject(String id) async {
    final r = await _dio.patch<Map<String, dynamic>>(
      '/supervision-invitations/doctor/$id/reject',
    );
    return Map<String, dynamic>.from(r.data ?? {});
  }

  Future<Map<String, dynamic>> defenseFinalMark(String projectId, int mark) async {
    final r = await _dio.patch<Map<String, dynamic>>(
      '/projects/$projectId/defense-final-mark',
      data: {'mark': mark},
    );
    return Map<String, dynamic>.from(r.data ?? {});
  }

  /// انتظار الاستلام يُزاد هنا حتى لا يقطع Dio قبل انتهاء توليد نموذج بطيء (حتى نحو ‎۶‎ دقيقة).
  Future<Map<String, dynamic>> aiChat({
    required String query,
    String conversationHistory = '',
    String model = 'qwen2.5:7b',
  }) async {
    final r = await _dio.post<Map<String, dynamic>>(
      '/integrations/ai/chat',
      data: {
        'query': query,
        'conversation_history': conversationHistory,
        'model': model,
      },
      options: Options(
        receiveTimeout: const Duration(seconds: 360),
        sendTimeout: const Duration(seconds: 60),
      ),
    );
    return r.data!;
  }

  /// بحث شبيه في فهرس المشاريع المتجهّ (FastAPI ‎`/api/search`‎ عبر Nest).
  Future<Map<String, dynamic>> aiVectorSearch({
    required String query,
    int k = 5,
  }) async {
    final kClamped = k < 1 ? 1 : (k > 10 ? 10 : k);
    final r = await _dio.post<Map<String, dynamic>>(
      '/integrations/ai/search',
      data: {
        'query': query,
        'k': kClamped,
      },
      options: Options(
        receiveTimeout: const Duration(seconds: 120),
        sendTimeout: const Duration(seconds: 60),
      ),
    );
    return r.data!;
  }

  /// أسماء النماذج المتاحة (من الخادوم أو احتياطيًا من Ollama عبر Nest).
  Future<List<String>> aiChatModels() async {
    final r = await _dio.get<Map<String, dynamic>>('/integrations/ai/models');
    final data = r.data;
    if (data == null) {
      return const ['qwen2.5:7b'];
    }
    final raw = data['models'];
    if (raw is! List) {
      return const ['qwen2.5:7b'];
    }
    final names = raw
        .map((e) => e?.toString().trim() ?? '')
        .where((s) => s.isNotEmpty)
        .toList();
    return names.isEmpty ? const ['qwen2.5:7b'] : names;
  }

  Future<Map<String, dynamic>> _post(String path, Map<String, dynamic> data) async {
    final r = await _dio.post<Map<String, dynamic>>(path, data: data);
    return r.data!;
  }

  Future<List<dynamic>> _getList(String path) async {
    final r = await _dio.get<dynamic>(path);
    final data = r.data;
    if (data is List) {
      return data;
    }
    if (data is Map) {
      final raw = data['data'] ?? data['items'];
      if (raw is List) {
        return List<dynamic>.from(raw);
      }
    }
    throw StateError(
      'لم نستلم قائمة من $path — نتيجة بنوع ${data.runtimeType}',
    );
  }
}
