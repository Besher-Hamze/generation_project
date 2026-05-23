import 'package:flutter/material.dart';

import 'app/grad_hub_root.dart';
import 'core/config/saved_server_ip.dart';
import 'core/network/dio_client.dart';
import 'core/theme/app_theme.dart';
import 'data/grad_hub_api.dart';
import 'features/setup/enter_server_ip_screen.dart';
import 'providers/auth_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const _Startup());
}

/// يحمّل IP المحفوظ أو يطلبها مرة واحدة فقط؛ ثم يشغّل التطبيق.
class _Startup extends StatefulWidget {
  const _Startup();

  @override
  State<_Startup> createState() => _StartupState();
}

class _StartupState extends State<_Startup> {
  String? _ip;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final ip = await loadSavedServerIp();
    if (!mounted) {
      return;
    }
    setState(() {
      _loading = false;
      _ip = ip;
    });
  }

  Future<void> _saveAndContinue(String ip) async {
    await saveServerIp(ip);
    if (!mounted) {
      return;
    }
    setState(() => _ip = ip);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return MaterialApp(
        theme: AppTheme.light(),
        debugShowCheckedModeBanner: false,
        home: const Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }

    if (_ip == null) {
      return MaterialApp(
        theme: AppTheme.light(),
        debugShowCheckedModeBanner: false,
        home: EnterServerIpScreen(onContinue: _saveAndContinue),
      );
    }

    final dio = createDioForHost(_ip!);
    final api = GradHubApi(dio);
    final auth = AuthProvider(api, dio);
    return GradHubRoot(dio: dio, api: api, auth: auth);
  }
}
