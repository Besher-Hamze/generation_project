import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:manage_projects/app/grad_hub_root.dart';
import 'package:manage_projects/core/network/dio_client.dart';
import 'package:manage_projects/data/grad_hub_api.dart';
import 'package:manage_projects/providers/auth_provider.dart';

void main() {
  testWidgets('Auth gate shows splash while bootstrapping', (tester) async {
    final dio = createDioForHost('127.0.0.1');
    final api = GradHubApi(dio);
    final auth = AuthProvider(api, dio);
    await tester.pumpWidget(
      GradHubRoot(dio: dio, api: api, auth: auth),
    );
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsWidgets);
  });
}
