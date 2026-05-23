import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// خطوة أولى: حقل واحد للـ IP فقط؛ الاتصال يكون إلى `http://IP:3000/api`.
class EnterServerIpScreen extends StatefulWidget {
  const EnterServerIpScreen({super.key, required this.onContinue});

  final Future<void> Function(String ip) onContinue;

  @override
  State<EnterServerIpScreen> createState() => _EnterServerIpScreenState();
}

class _EnterServerIpScreenState extends State<EnterServerIpScreen> {
  final _c = TextEditingController();
  bool _busy = false;
  String? _err;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  Future<void> _go() async {
    final raw = _c.text.trim();
    if (raw.isEmpty) {
      setState(() => _err = 'اكتب عنوان IP');
      return;
    }
    setState(() {
      _busy = true;
      _err = null;
    });
    try {
      await widget.onContinue(raw);
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: DecoratedBox(
        decoration: AppTheme.meshBackground(context),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'عنوان الخادم',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'اكتب IP فقط. المنفذ دائماً 3000 (مثل http://YOUR_IP:3000).',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.outline,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _c,
                  autofocus: true,
                  keyboardType: TextInputType.text,
                  autocorrect: false,
                  decoration: const InputDecoration(
                    labelText: 'IP',
                    hintText: '192.168.1.10 أو 10.0.2.2',
                  ),
                  onSubmitted: (_) => _busy ? null : _go(),
                ),
                if (_err != null) ...[
                  const SizedBox(height: 8),
                  Text(_err!, style: TextStyle(color: theme.colorScheme.error)),
                ],
                const Spacer(),
                FilledButton(
                  onPressed: _busy ? null : _go,
                  child: _busy
                      ? const SizedBox.square(
                          dimension: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('متابعة'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
