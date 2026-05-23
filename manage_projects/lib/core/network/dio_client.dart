import 'package:dio/dio.dart';

/// [hostIp] مثل 192.168.1.10 — المنفذ ثابت 3000 تحت مسار `/api`.
Dio createDioForHost(String hostIp) {
  final ip = hostIp.trim();
  return Dio(
    BaseOptions(
      baseUrl: 'http://$ip:3000/api',
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 120),
      headers: const {'Accept': 'application/json'},
    ),
  );
}
