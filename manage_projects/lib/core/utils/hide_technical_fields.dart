/// مفاتيح لا تُعرض للمستخدم (معرّفات ومفاتيح نظام).
bool isTechnicalKey(String k) {
  if (k == '_id' || k == 'id' || k == '__v') {
    return true;
  }
  if (k.endsWith('Id') || k.endsWith('_id')) {
    return true;
  }
  return false;
}

/// عنوان عربي بسيط لبعض المفاتيح الشائعة.
String? arabicLabelForKey(String k) {
  return switch (k) {
    'name' => 'الاسم',
    'email' => 'البريد',
    'uniNumber' => 'الرقم الجامعي',
    'officeNo' => 'المكتب',
    'phone' => 'الهاتف',
    'title' => 'العنوان',
    'description' => 'الوصف',
    'academicYear' => 'العام الدراسي',
    'orderStart' => 'بداية التسجيل',
    'orderStatus' => 'حالة الدورة',
    'mark' => 'العلامة',
    'notes' => 'ملاحظات',
    'heldAt' => 'التاريخ',
    'sessionNum' => 'رقم الجلسة',
    'supervisorDisplayName' => 'المشرف (من المصدر)',
    'label' => 'التسمية',
    'status' => 'الحالة',
    'isFinished' => 'مكتمل',
    'project' => 'المشروع',
    'doctor' => 'المشرف',
    'requester' => 'المتقدّم',
    'supervisor' => 'المشرف',
    _ => null,
  };
}

/// يُعتبر اسمَ كائن MongoDB خام (24 خانة hex) — لا يُعرَض كنصّ للمستخدم.
bool looksLikeMongoId(Object? v) {
  final s = v?.toString() ?? '';
  if (s.length != 24) {
    return false;
  }
  return RegExp(r'^[a-f0-9A-F]{24}$').hasMatch(s);
}

String formatPublicScalar(dynamic v) {
  if (v == null) {
    return '';
  }
  if (v is bool) {
    return v ? 'نعم' : 'لا';
  }
  if (v is num || v is String) {
    final s = v.toString();
    if (s.isEmpty || looksLikeMongoId(s)) {
      return '';
    }
    return s;
  }
  return '';
}

/// جمع حقول مقروءة لتفاصيل سجل إداري (بدون معرّفات أو JSON خام).
void collectPublicFields(
  Map<dynamic, dynamic> raw,
  List<MapEntry<String, String>> out, {
  String prefixAr = '',
}) {
  final m = Map<String, dynamic>.from(raw);
  for (final e in m.entries) {
    final key = e.key;
    if (isTechnicalKey(key)) {
      continue;
    }
    final ar = arabicLabelForKey(key) ?? key;
    final label = prefixAr.isEmpty ? ar : '$prefixAr › $ar';
    final val = e.value;
    if (val is Map) {
      collectPublicFields(val, out, prefixAr: label);
    } else if (val is List) {
      if (val.isEmpty) {
        continue;
      }
      final head = val.first;
      if (head is Map) {
        collectPublicFields(head, out, prefixAr: label);
      } else {
        final joined = val
            .map(formatPublicScalar)
            .where((s) => s.isNotEmpty)
            .join('، ');
        if (joined.isNotEmpty) {
          out.add(MapEntry(label, joined));
        }
      }
    } else {
      final s = formatPublicScalar(val);
      if (s.isNotEmpty) {
        out.add(MapEntry(label, s));
      }
    }
  }
}

String summarizePublicRecord(Map<String, dynamic> m, {int maxParts = 4}) {
  final pairs = <MapEntry<String, String>>[];
  collectPublicFields(m, pairs);
  if (pairs.isEmpty) {
    return '—';
  }
  return pairs
      .take(maxParts)
      .map((e) => '${e.key}: ${e.value}')
      .join(' · ');
}
