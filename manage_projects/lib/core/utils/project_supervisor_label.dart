/// تسمية مختصرة لمشرفي المشروع من JSON مُعبّأ (بدون عرض معرفات).
String projectSupervisorsShortLabel(Map<String, dynamic> proj) {
  final names = <String>[];
  final s = proj['supervisor'];
  if (s is Map && (s['name']?.toString().isNotEmpty == true)) {
    names.add(s['name']!.toString());
  }
  final ss = proj['supervisors'];
  if (ss is List) {
    for (final x in ss) {
      if (x is Map && (x['name']?.toString().isNotEmpty == true)) {
        final n = x['name']!.toString();
        if (!names.contains(n)) {
          names.add(n);
        }
      }
    }
  }
  if (names.isNotEmpty) {
    return names.join('، ');
  }
  final raw = proj['supervisorDisplayName']?.toString().trim();
  if (raw != null && raw.isNotEmpty) {
    return raw;
  }
  return '—';
}
