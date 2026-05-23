import 'package:shared_preferences/shared_preferences.dart';

const _k = 'saved_api_host_ip';

Future<String?> loadSavedServerIp() async {
  final p = await SharedPreferences.getInstance();
  final v = p.getString(_k)?.trim();
  if (v == null || v.isEmpty) {
    return null;
  }
  return v;
}

Future<void> saveServerIp(String ip) async {
  final p = await SharedPreferences.getInstance();
  await p.setString(_k, ip.trim());
}
