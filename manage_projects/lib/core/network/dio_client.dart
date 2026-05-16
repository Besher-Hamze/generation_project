import 'package:dio/dio.dart';

import '../../config/api_config.dart';

Dio createDio() {
  return Dio(
    BaseOptions(
      baseUrl: '${ApiConfig.baseUrl}/api',
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 120),
      headers: const {'Accept': 'application/json'},
    ),
  );
}
