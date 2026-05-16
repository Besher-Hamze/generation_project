/// العام الدراسي «الحالي» بافتراض أن السنة تبدأ من أيلول (شائع بالجامعات العربية).
String activeAcademicYearLabelForNow([DateTime? ref]) {
  final d = ref ?? DateTime.now();
  final y = d.year;
  if (d.month >= 9) {
    return formatAcademicYearRangeFromStartYear(y);
  }
  return formatAcademicYearRangeFromStartYear(y - 1);
}

/// صيغة موحَّدة للعرض وللخادم: `سنةالبداية-سنةالنهاية` (مثل 2025-2026).
String formatAcademicYearRangeFromStartYear(int startYear) =>
    '$startYear-${startYear + 1}';

/// تاريخ وسيط لتبويب عام [CalendarDatePicker] (منتقي سنة البداية).
DateTime calendarAnchorForAcademicYearField(String fieldText,
    [DateTime? clock]) {
  final ref = clock ?? DateTime.now();
  final fallbackStart = ref.month >= 9 ? ref.year : ref.year - 1;
  final raw = fieldText.trim();
  if (raw.isNotEmpty) {
    final sy = academicYearStartDigits(raw);
    if (sy >= 0) {
      return DateTime(sy, 6, 15);
    }
  }
  final activeStart =
      academicYearStartDigits(activeAcademicYearLabelForNow(ref));
  return DateTime(activeStart >= 0 ? activeStart : fallbackStart, 6, 15);
}

/// القيمة المخزَّنة في `academicYear` من سنة المنتقي (`d.year` = سنة البداية).
String academicYearLabelFromPickerDate(DateTime d) =>
    formatAcademicYearRangeFromStartYear(d.year);

int academicYearStartDigits(String academicYearLabel) {
  final head = academicYearLabel.split(RegExp(r'[-\/]')).first.trim();
  final digits = RegExp(r'\d+').firstMatch(head)?.group(0);
  return int.tryParse(digits ?? '') ?? -1;
}

/// مشروع **غير مكتمل** وعامُه يطابق العام النشط المعتمد على التقويم المحلي للجهاز.
bool projectMatchesActiveAcademicYearAndNotFinished(Map<String, dynamic> m) {
  if (m['isFinished'] == true) {
    return false;
  }
  final raw = m['academicYear']?.toString().trim() ?? '';
  if (raw.isEmpty || raw == 'null') {
    return false;
  }
  final expected = activeAcademicYearLabelForNow();
  if (raw == expected) {
    return true;
  }
  final a = academicYearStartDigits(raw);
  final b = academicYearStartDigits(expected);
  if (a >= 0 && b >= 0) {
    return a == b;
  }
  return false;
}
