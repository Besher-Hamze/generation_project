import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../data/grad_hub_api.dart';
import '../../providers/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({
    super.key,
    required this.api,
    required this.auth,
  });

  final GradHubApi api;
  final AuthProvider auth;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _uni = TextEditingController();
  final _name = TextEditingController();
  final _pass = TextEditingController();

  List<dynamic> _depts = [];
  String? _dept;

  bool _loading = true;
  bool _submit = false;
  String? _err;

  @override
  void dispose() {
    _uni.dispose();
    _name.dispose();
    _pass.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPublic());
  }

  Future<void> _loadPublic() async {
    setState(() => _loading = true);
    try {
      final d = await widget.api.publicDepartments();
      setState(() {
        _depts = d;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _err = '$e';
        _loading = false;
      });
    }
  }

  Future<void> _register() async {
    if (_dept == null) {
      setState(() => _err = 'انتقِ القسم.');
      return;
    }
    setState(() {
      _submit = true;
      _err = null;
    });
    try {
      final body = await widget.api.studentRegister({
        'uniNumber': _uni.text.trim(),
        'name': _name.text.trim(),
        'password': _pass.text,
        'department': _dept!,
      });
      await widget.auth.persistFromRegistration(body);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } on DioException catch (e) {
      setState(() => _err = e.response?.data?.toString() ?? e.message);
    } catch (e) {
      setState(() => _err = e.toString());
    } finally {
      if (mounted) {
        setState(() => _submit = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('تسجيل طالب')),
      body: DecoratedBox(
        decoration: AppTheme.meshBackground(context),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_err != null)
                      Text(_err!, style: TextStyle(color: theme.colorScheme.error)),
                    TextField(
                      controller: _uni,
                      decoration: const InputDecoration(labelText: 'الرقم الجامعي'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _name,
                      decoration: const InputDecoration(labelText: 'الاسم'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _pass,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'كلمة المرور (٦ أحرف فأكثر)',
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      // ignore: deprecated_member_use
                      value: _dept,
                      decoration: const InputDecoration(labelText: 'القسم'),
                      items: [
                        for (final x in _depts)
                          if (x is Map && x['_id'] != null)
                            DropdownMenuItem(
                              value: x['_id']!.toString(),
                              child: Text(x['name']?.toString() ?? ''),
                            ),
                      ],
                      onChanged: (v) => setState(() => _dept = v),
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _submit ? null : _register,
                      child: _submit
                          ? const SizedBox.square(
                              dimension: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('إنشاء الحساب'),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
