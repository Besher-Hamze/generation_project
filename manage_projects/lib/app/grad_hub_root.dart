import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/widgets/app_logo.dart';
import '../core/theme/app_theme.dart';
import '../data/grad_hub_api.dart';
import '../features/auth/login_screen.dart';
import '../features/shell/main_shell.dart';
import '../providers/auth_provider.dart';

class GradHubRoot extends StatelessWidget {
  const GradHubRoot({
    super.key,
    required this.dio,
    required this.api,
    required this.auth,
  });

  final Dio dio;
  final GradHubApi api;
  final AuthProvider auth;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<Dio>.value(value: dio),
        Provider<GradHubApi>.value(value: api),
        ChangeNotifierProvider<AuthProvider>.value(value: auth),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'مرشد — مشاريع التخرّج',
        theme: AppTheme.light(),
        themeMode: ThemeMode.light,
        builder: (ctx, child) =>
            Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox.shrink(),
        ),
        home: const _AuthGate(),
      ),
    );
  }
}

class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().bootstrap();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    Widget child;
    if (!auth.isReady) {
      child = const _Splash();
    } else if (!auth.isAuthenticated) {
      child = const LoginScreen();
    } else {
      child = MainShell(key: ValueKey(auth.role ?? ''));
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 450),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      child: KeyedSubtree(
        key: ValueKey('${auth.isReady}_${auth.isAuthenticated}_${auth.role}'),
        child: child,
      ),
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: DecoratedBox(
        decoration: AppTheme.meshBackground(context),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AppLogo(size: 64),
              const SizedBox(height: 20),
              Text(
                'مرشد',
                style: theme.textTheme.headlineMedium,
              ),
              const SizedBox(height: 10),
              Text(
                'مركز مشاريع التخرّج',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              const SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(strokeWidth: 2.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
