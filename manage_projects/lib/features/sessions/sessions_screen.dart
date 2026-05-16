import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/utils/academic_year.dart';
import '../../core/utils/hide_technical_fields.dart';
import '../../core/utils/mongo_ref.dart';
import '../../data/grad_hub_api.dart';
import '../../providers/auth_provider.dart';

bool doctorSupervisesProject(Map<String, dynamic> m, String doctorId) {
  if (doctorId.isEmpty) {
    return false;
  }
  final sup = mongoRefId(m['supervisor']);
  if (sup != null && sup == doctorId) {
    return true;
  }
  final ss = m['supervisors'];
  if (ss is List) {
    for (final x in ss) {
      if (mongoRefId(x) == doctorId) {
        return true;
      }
    }
  }
  return false;
}

class SessionsScreen extends StatefulWidget {
  const SessionsScreen({super.key, this.showCreateHint = false});

  /// تلميح للدكتور فقط؛ الإدارة لا تحتاجه.
  final bool showCreateHint;

  @override
  State<SessionsScreen> createState() => _SessionsScreenState();
}

class _SessionsScreenState extends State<SessionsScreen> {
  Future<List<dynamic>>? _future;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  void _reload() {
    if (!mounted) {
      return;
    }
    final role = context.read<AuthProvider>().role;
    setState(() {
      if (role == 'admin') {
        _future = Future<List<dynamic>>.value([]);
      } else {
        _future = context.read<GradHubApi>().sessionsMe();
      }
    });
  }

  Future<void> _openCreateSession() async {
    final api = context.read<GradHubApi>();
    final auth = context.read<AuthProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final role = auth.role ?? '';

    if (role == 'doctor') {
      final myId = auth.user?['id']?.toString();
      if (myId == null || myId.isEmpty) {
        return;
      }
      final all = await api.getList('/projects');
      final supervised = <Map<String, dynamic>>[];
      for (final raw in all) {
        if (raw is! Map) {
          continue;
        }
        final m = Map<String, dynamic>.from(raw);
        if (doctorSupervisesProject(m, myId) &&
            projectMatchesActiveAcademicYearAndNotFinished(m)) {
          supervised.add(m);
        }
      }
      if (!mounted) {
        return;
      }
      if (supervised.isEmpty) {
        final y = activeAcademicYearLabelForNow();
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              'لا مشاريع «قيد العمل» للعام $y تحت إشرافك (أو العام المخزّن في النظام لا يطابق $y).',
            ),
          ),
        );
        return;
      }
      await showDialog<void>(
        context: context,
        builder: (ctx) => _CreateSessionDialog(doctorProjects: supervised),
      );
      if (mounted) {
        _reload();
      }
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final theme = Theme.of(context);
    final role = auth.role ?? '';
    final canCreateSession = role == 'doctor';

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('جلسات الإشراف')),
      floatingActionButton: canCreateSession
          ? FloatingActionButton.extended(
              onPressed: _openCreateSession,
              icon: const Icon(Icons.add_rounded),
              label: const Text('جلسة جديدة'),
            )
          : null,
      body: role == 'admin'
          ? Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 100),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            size: 44,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'حساب الإدارة',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'لا يُسمح بتسجيل أو تعديل جلسات إشراف من الإدارة. '
                            'الدكتور المشرف على المشروع يسجّل الجلسات من تبويب «جلسات» أو «إشرافي».',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              height: 1.45,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            )
          : FutureBuilder<List<dynamic>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('${snap.error}'));
          }
          final list = snap.data ?? [];
          return Column(
            children: [
              if (widget.showCreateHint && role == 'doctor')
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(
                            Icons.event_available_rounded,
                            color: theme.colorScheme.secondary,
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'تظهر لمشاريعك قيد العمل للعام الحالي فقط. سجّل الجلسة بعنوان وعلامة وملاحظات — يظهر للطالب وللفريق.',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              Expanded(
                child: list.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            canCreateSession
                                ? 'لا جلسات بعد. اضغط «جلسة جديدة» للبدء.'
                                : 'لا جلسات لعرضها',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : RefreshIndicator.adaptive(
                        onRefresh: () async {
                          _reload();
                          await Future<void>.delayed(
                            const Duration(milliseconds: 80),
                          );
                          await _future;
                        },
                        child: ListView.separated(
                          padding:
                              const EdgeInsets.fromLTRB(16, 12, 16, 100),
                          itemCount: list.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 9),
                          itemBuilder: (_, i) {
                            final m = Map<String, dynamic>.from(
                              list[i] as Map,
                            );
                            final ttl = m['title']?.toString() ?? '';
                            final pairs = <MapEntry<String, String>>[];
                            collectPublicFields(m, pairs);

                            return Card(
                              child: ExpansionTile(
                                title: Text(
                                  ttl.trim().isEmpty ? 'جلسة' : ttl,
                                ),
                                subtitle: Text(
                                  'العلامة: ${m['mark'] ?? '—'}  ·  ${_short(m['notes'])}',
                                ),
                                children: [
                                  if (pairs.isEmpty)
                                    Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Text(
                                        'لا تفاصيل إضافية بعد إخفاء المعرفات.',
                                        style: theme.textTheme.bodyMedium,
                                      ),
                                    )
                                  else
                                    ...pairs.map(
                                      (e) => ListTile(
                                        title: Text(
                                          e.key,
                                          style: theme.textTheme.labelLarge
                                              ?.copyWith(
                                            color: theme
                                                .colorScheme.secondary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        subtitle: SelectableText(
                                          e.value,
                                          style: theme.textTheme.bodyMedium,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  static String _short(dynamic n) =>
      n == null ? '' : n.toString().split('\n').first;
}

class _CreateSessionDialog extends StatefulWidget {
  const _CreateSessionDialog({required this.doctorProjects});

  final List<Map<String, dynamic>> doctorProjects;

  @override
  State<_CreateSessionDialog> createState() => _CreateSessionDialogState();
}

class _CreateSessionDialogState extends State<_CreateSessionDialog> {
  late String? _projectId;
  final _title = TextEditingController(text: 'جلسة إشراف');
  final _mark = TextEditingController(text: '0');
  final _notes = TextEditingController();

  bool _busy = false;
  String? _err;

  @override
  void initState() {
    super.initState();
    final list = widget.doctorProjects;
    _projectId = list.first['_id']?.toString();
  }

  @override
  void dispose() {
    _title.dispose();
    _mark.dispose();
    _notes.dispose();
    super.dispose();
  }

  List<DropdownMenuItem<String>> _projectItems() {
    return widget.doctorProjects
        .map((p) {
          final id = p['_id']?.toString() ?? '';
          if (id.isEmpty) {
            return null;
          }
          final t = p['title']?.toString() ?? 'مشروع';
          final y = p['academicYear']?.toString() ?? '';
          return DropdownMenuItem<String>(
            value: id,
            child: Text(
              y.isEmpty ? t : '$t · $y',
              overflow: TextOverflow.ellipsis,
            ),
          );
        })
        .whereType<DropdownMenuItem<String>>()
        .toList();
  }

  Future<void> _submit() async {
    final pid = _projectId;
    if (pid == null || pid.isEmpty) {
      setState(() => _err = 'اختر مشروعاً');
      return;
    }
    final markVal = int.tryParse(_mark.text.trim());
    if (markVal == null) {
      setState(() => _err = 'العلامة رقم صحيح');
      return;
    }

    final api = context.read<GradHubApi>();
    setState(() {
      _busy = true;
      _err = null;
    });

    try {
      await api.createSession(
        projectId: pid,
        mark: markVal,
        notes: _notes.text.trim(),
        title: _title.text.trim(),
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إنشاء الجلسة')),
      );
    } on DioException catch (e) {
      setState(() {
        _busy = false;
        _err = '${e.response?.data ?? e.message}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final projectItems = _projectItems();
    final projectValues =
        projectItems.map((i) => i.value).whereType<String>().toList();
    final projectDropdownValue =
        _projectId != null && projectValues.contains(_projectId)
            ? _projectId!
            : (projectValues.isNotEmpty ? projectValues.first : null);

    final maxW = math.min(MediaQuery.sizeOf(context).width - 40, 440.0);

    return AlertDialog(
      title: const Text('جلسة إشراف جديدة'),
      content: SizedBox(
        width: maxW,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                isExpanded: true,
                value: projectDropdownValue,
                decoration: const InputDecoration(labelText: 'المشروع'),
                items: projectItems,
                onChanged: _busy
                    ? null
                    : (v) => setState(() => _projectId = v),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _title,
                enabled: !_busy,
                decoration: const InputDecoration(labelText: 'عنوان الجلسة'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _mark,
                enabled: !_busy,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'العلامة',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _notes,
                enabled: !_busy,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'ملاحظات (اختياري)',
                ),
              ),
              if (_err != null) ...[
                const SizedBox(height: 12),
                Text(
                  _err!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: _busy ? null : _submit,
          child: _busy
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('حفظ'),
        ),
      ],
    );
  }
}
/// حوار تسجيل جلسة للدكتور من أي شاشة (مشاريع تحت الإشراف، إلخ).
Future<void> showDoctorCreateSessionDialog(
  BuildContext context, {
  required List<Map<String, dynamic>> doctorProjects,
}) async {
  if (doctorProjects.isEmpty || !context.mounted) {
    return;
  }
  await showDialog<void>(
    context: context,
    builder: (ctx) => _CreateSessionDialog(doctorProjects: doctorProjects),
  );
}
