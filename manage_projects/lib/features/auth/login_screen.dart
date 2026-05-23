import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_logo.dart';
import '../../data/grad_hub_api.dart';
import '../../providers/auth_provider.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  int _role = 2;
  final _c1 = TextEditingController();
  final _c2 = TextEditingController();
  bool _busy = false;
  String? _err;

  @override
  void dispose() {
    _c1.dispose();
    _c2.dispose();
    super.dispose();
  }

  Future<void> _go() async {
    setState(() {
      _busy = true;
      _err = null;
    });
    final auth = context.read<AuthProvider>();
    try {
      final a = _c1.text.trim();
      final b = _c2.text;
      switch (_role) {
        case 0:
          await auth.loginAdmin(a, b);
        case 1:
          await auth.loginDoctor(a, b);
        default:
          await auth.loginStudent(a, b);
      }
    } on DioException catch (e) {
      setState(() => _err = e.response?.data?.toString() ?? e.message);
    } catch (e) {
      setState(() => _err = e.toString());
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label1 = _role == 2 ? 'الرقم الجامعي' : 'البريد الإلكتروني';
    final hint1 = _role == 2 ? 'مثال: 20215001' : 'admin@univ.edu';

    return Scaffold(
      body: DecoratedBox(
        decoration: AppTheme.meshBackground(context),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
              top: 28,
            ),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const AppLogo(size: 52),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'مرشد',
                        style: theme.textTheme.headlineMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'مركز مشاريع التخرّج — طالب • دكتور • مشرف',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.44,
                  ),
                ),
                const SizedBox(height: 28),
                SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 0, label: Text('مشرف')),
                    ButtonSegment(value: 1, label: Text('دكتور')),
                    ButtonSegment(value: 2, label: Text('طالب')),
                  ],
                  selected: {_role},
                  onSelectionChanged: (s) {
                    setState(() {
                      _role = s.first;
                      _err = null;
                      _c1.clear();
                    });
                  },
                ),
                const SizedBox(height: 22),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_err != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: Text(
                              _err!,
                              style: TextStyle(color: theme.colorScheme.error),
                            ),
                          ),
                        TextField(
                          controller: _c1,
                          keyboardType: _role == 2
                              ? TextInputType.text
                              : TextInputType.emailAddress,
                          decoration: InputDecoration(labelText: label1, hintText: hint1),
                        ),
                        const SizedBox(height: 14),
                        TextField(
                          controller: _c2,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'كلمة المرور',
                          ),
                        ),
                        const SizedBox(height: 22),
                        FilledButton(
                          onPressed: _busy ? null : _go,
                          child: _busy
                              ? const SizedBox.square(
                                  dimension: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('دخول'),
                        ),
                        if (_role == 2) ...[
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () {
                              final api = context.read<GradHubApi>();
                              final auth = context.read<AuthProvider>();
                              Navigator.of(context).push<void>(
                                MaterialPageRoute<void>(
                                  builder: (_) => RegisterScreen(
                                    api: api,
                                    auth: auth,
                                  ),
                                ),
                              );
                            },
                            child: const Text('تسجيل طالب جديد'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
