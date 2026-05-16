/// عنوان خادوم Nest؛ غيّره حسب جهاز التطوير (أندرويد محاكي: 10.0.2.2).
abstract final class ApiConfig {
  /// مثال: `http://10.0.2.2:3000`
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.80.187.146:3000',
  );
}
