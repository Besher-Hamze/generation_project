import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/mongo_ref.dart';
import '../../data/grad_hub_api.dart';
import 'sessions_screen.dart';

/// تفاصيل مشروع تحت إشراف الدكتور مع تسجيل جلسات وعرض الجلسات السابقة لهذا المشروع.
class DoctorProjectSupervisionHubScreen extends StatefulWidget {
  const DoctorProjectSupervisionHubScreen({super.key, required this.projectId});

  final String projectId;

  @override
  State<DoctorProjectSupervisionHubScreen> createState() =>
      _DoctorProjectSupervisionHubScreenState();
}

class _DoctorProjectSupervisionHubScreenState
    extends State<DoctorProjectSupervisionHubScreen> {
  int _token = 0;

  void _bump() => setState(() => _token++);

  Future<_HubBundle> _load(GradHubApi api) async {
    final project = await api.getProject(widget.projectId);
    final sessionsRaw = await api.sessionsMe();
    final sessions = sessionsRaw.whereType<Map>().map((e) {
      return Map<String, dynamic>.from(e);
    }).toList();

    final mine = sessions.where((s) {
      return mongoRefId(s['project']) == widget.projectId;
    }).toList();

    mine.sort((a, b) {
      final da = _dateKey(a);
      final db = _dateKey(b);
      return db.compareTo(da);
    });

    return _HubBundle(project: project, sessionsForProject: mine);
  }

  static String _dateKey(Map<String, dynamic> s) {
    final c = s['createdAt'] ?? s['heldAt'];
    return c?.toString() ?? '';
  }

  Future<void> _addSession(Map<String, dynamic> projectRow) async {
    await showDoctorCreateSessionDialog(
      context,
      doctorProjects: [projectRow],
    );
    if (mounted) {
      _bump();
    }
  }

  @override
  Widget build(BuildContext context) {
    final api = context.read<GradHubApi>();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(title: const Text('مشروع تحت إشرافي')),
      body: FutureBuilder<_HubBundle>(
        key: ValueKey(_token),
        future: _load(api),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError || snap.data == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('${snap.error ?? 'فشل التحميل'}'),
              ),
            );
          }
          final bundle = snap.data!;
          final p = bundle.project;
          final title = p['title']?.toString() ?? 'مشروع';
          final year = p['academicYear']?.toString() ?? '';
          final desc = p['description']?.toString() ?? '';
          final sessions = bundle.sessionsForProject;

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              Text(
                title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  if (year.isNotEmpty)
                    Chip(
                      avatar: const Icon(Icons.calendar_month_rounded, size: 18),
                      label: Text(year),
                    ),
                  Chip(
                    avatar: Icon(
                      Icons.pending_actions_rounded,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                    label: const Text('غير مكتمل'),
                  ),
                ],
              ),
              if (desc.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  'وصف المشروع',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(desc, style: theme.textTheme.bodyLarge?.copyWith(height: 1.5)),
              ],
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => _addSession(p),
                icon: const Icon(Icons.add_circle_outline_rounded),
                label: const Text('تسجيل جلسة إشراف'),
              ),
              const SizedBox(height: 10),
              TextButton.icon(
                onPressed: _bump,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('تحديث القائمة'),
              ),
              const SizedBox(height: 20),
              Text(
                'جلسات هذا المشروع',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              if (sessions.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'لا جلسات مسجّلة بعد لهذا المشروع.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                )
              else
                ...sessions.map((s) {
                  final ttl = s['title']?.toString().trim();
                  final mark = s['mark'];
                  final notes = s['notes']?.toString() ?? '';
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      title: Text(
                        (ttl != null && ttl.isNotEmpty) ? ttl : 'جلسة',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        'العلامة: $mark${notes.isNotEmpty ? '\n$notes' : ''}',
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }
}

class _HubBundle {
  _HubBundle({
    required this.project,
    required this.sessionsForProject,
  });

  final Map<String, dynamic> project;
  final List<Map<String, dynamic>> sessionsForProject;
}
