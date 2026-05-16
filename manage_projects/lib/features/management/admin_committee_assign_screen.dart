import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/academic_year.dart';
import '../../core/utils/mongo_ref.dart';
import '../../data/grad_hub_api.dart';

/// يعرض المشاريع **قيد العمل** ويضبط لكل مشروع اللجنة المرتبطة (أو إلغاء الربط).
class AdminCommitteeAssignScreen extends StatefulWidget {
  const AdminCommitteeAssignScreen({super.key});

  @override
  State<AdminCommitteeAssignScreen> createState() =>
      _AdminCommitteeAssignScreenState();
}

class _AdminCommitteeAssignScreenState extends State<AdminCommitteeAssignScreen> {
  Future<_AssignBundle>? _bundle;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  void _reload() {
    setState(() {
      _bundle = _load(context.read<GradHubApi>());
    });
  }

  Future<_AssignBundle> _load(GradHubApi api) async {
    final projectsRaw = await api.getList('/projects');
    final committeesRaw = await api.getList('/committees');
    final projects = projectsRaw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .where(projectMatchesActiveAcademicYearAndNotFinished)
        .toList()
      ..sort((a, b) {
        final ta = '${a['title']}';
        final tb = '${b['title']}';
        return ta.compareTo(tb);
      });
    final committees = committeesRaw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList()
      ..sort((a, b) {
        final la = '${a['label'] ?? a['_id']}';
        final lb = '${b['label'] ?? b['_id']}';
        return la.compareTo(lb);
      });
    return _AssignBundle(projects: projects, committees: committees);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('توزيع مشاريع العام الحالي على اللجان'),
        actions: [
          IconButton(
            tooltip: 'تحديث',
            onPressed: _reload,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: FutureBuilder<_AssignBundle>(
        future: _bundle,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('${snap.error}'),
            ),);
          }
          final bundle = snap.data!;
          if (bundle.committees.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'لا توجد لجان مسجّلة بعد.\nمن «إنشاء لجنة» أو «البيانات» أنشئ لجنة ثم ارجع هنا.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge,
                ),
              ),
            );
          }
          if (bundle.projects.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'لا مشاريع «قيد العمل» لهذا العام الدراسي في القائمة.',
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            itemCount: bundle.projects.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final m = bundle.projects[i];
              final id = m['_id']?.toString() ?? '';
              return _ProjectCommitteeTile(
                key: ValueKey(id),
                project: m,
                projectId: id,
                committees: bundle.committees,
                onAfterSave: _reload,
              );
            },
          );
        },
      ),
    );
  }
}

class _AssignBundle {
  const _AssignBundle({
    required this.projects,
    required this.committees,
  });

  final List<Map<String, dynamic>> projects;
  final List<Map<String, dynamic>> committees;
}

class _ProjectCommitteeTile extends StatefulWidget {
  const _ProjectCommitteeTile({
    super.key,
    required this.project,
    required this.projectId,
    required this.committees,
    required this.onAfterSave,
  });

  final Map<String, dynamic> project;
  final String projectId;
  final List<Map<String, dynamic>> committees;
  final VoidCallback onAfterSave;

  @override
  State<_ProjectCommitteeTile> createState() => _ProjectCommitteeTileState();
}

class _ProjectCommitteeTileState extends State<_ProjectCommitteeTile> {
  String? _selectedCommitteeId;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _syncFromProject();
  }

  void _syncFromProject() {
    final fromServer = mongoRefId(widget.project['committees']);
    final valid = <String?>{
      null,
      for (final c in widget.committees)
        if ((c['_id']?.toString() ?? '').isNotEmpty) c['_id']!.toString(),
    };
    _selectedCommitteeId = valid.contains(fromServer) ? fromServer : null;
  }

  @override
  void didUpdateWidget(covariant _ProjectCommitteeTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.projectId != widget.projectId ||
        mongoRefId(oldWidget.project['committees']) !=
            mongoRefId(widget.project['committees']) ||
        oldWidget.committees.length != widget.committees.length) {
      _syncFromProject();
    }
  }

  Future<void> _apply(String? newId) async {
    if (widget.projectId.isEmpty || _busy) {
      return;
    }
    setState(() {
      _busy = true;
      _selectedCommitteeId = newId;
    });
    final api = context.read<GradHubApi>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      await api.adminPatchProject(widget.projectId, {
        'committees': newId,
      });
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(
        const SnackBar(content: Text('تم حفظ ربط اللجنة.')),
      );
      widget.onAfterSave();
    } on DioException catch (e) {
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(
        SnackBar(content: Text('${e.response?.data ?? e.message}')),
      );
      setState(_syncFromProject);
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = widget.project['title']?.toString() ?? 'مشروع';
    final year = widget.project['academicYear']?.toString() ?? '';
    final dropdownValue = _selectedCommitteeId;

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (_busy)
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            if (year.isNotEmpty) ...[
              const SizedBox(height: 6),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: Chip(
                  visualDensity: VisualDensity.compact,
                  avatar: const Icon(Icons.calendar_month_rounded, size: 16),
                  label: Text(year, style: theme.textTheme.labelMedium),
                ),
              ),
            ],
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              value: dropdownValue,
              decoration: const InputDecoration(
                labelText: 'اللجنة',
                hintText: 'اختر اللجنة',
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('بدون لجنة'),
                ),
                ...widget.committees
                    .where((c) => (c['_id']?.toString() ?? '').isNotEmpty)
                    .map((c) {
                  final cid = c['_id']!.toString();
                  final label = c['label']?.toString().trim();
                  final display =
                      (label != null && label.isNotEmpty) ? label : cid;
                  return DropdownMenuItem<String?>(
                    value: cid,
                    child: Text(display),
                  );
                }),
              ],
              onChanged: _busy
                  ? null
                  : (v) {
                      if (v != _selectedCommitteeId) {
                        _apply(v);
                      }
                    },
            ),
          ],
        ),
      ),
    );
  }
}
