import 'package:flutter/material.dart';

import 'app/grad_hub_root.dart';
import 'core/network/dio_client.dart';
import 'data/grad_hub_api.dart';
import 'providers/auth_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final dio = createDio();
  final api = GradHubApi(dio);
  final auth = AuthProvider(api, dio);
  runApp(GradHubRoot(dio: dio, api: api, auth: auth));
}
