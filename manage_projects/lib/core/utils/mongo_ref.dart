/// يستخرج معرفاً من حقول mongoose المأهولة أو ObjectId خام.
String? mongoRefId(dynamic raw) {
  if (raw == null || raw == 'null') {
    return null;
  }
  if (raw is Map && raw['_id'] != null) {
    return raw['_id'].toString();
  }
  final s = raw.toString();
  return s.isEmpty ? null : s;
}
