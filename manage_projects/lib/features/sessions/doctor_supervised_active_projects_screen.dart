import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/grad_hub_api.dart';
import '../../providers/auth_provider.dart';
import 'doctor_project_supervision_hub_screen.dart';
import 'sessions_screen.dart';

/// مشاريع الدكتور **تحت إشرافه** ولم تُعرَّف كـمكتملة بعد (`isFinished` ليس true).
class DoctorSupervisedActiveProjectsScreen extends StatefulWidget {
  const DoctorSupervisedActiveProjectsScreen({super.key});

  @override
  State<DoctorSupervisedActiveProjectsScreen> createState() =>
      _DoctorSupervisedActiveProjectsScreenState();
}

class _DoctorSupervisedActiveProjectsScreenState
    extends State<DoctorSupervisedActiveProjectsScreen> {
  Future<List<Map<String, dynamic>>>? _future;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  void _reload() {
    final api = context.read<GradHubApi>();
    final auth = context.read<AuthProvider>();
    final myId = auth.user?['id']?.toString() ?? '';
    setState(() {
      _future = _fetchSupervisedIncomplete(api, myId);
    });
  }

  static Future<List<Map<String, dynamic>>> _fetchSupervisedIncomplete(
    GradHubApi api,
    String doctorId,
  ) async {
    if (doctorId.isEmpty) {
      return [];
    }
    final all = await api.getList('/projects');
    final out = <Map<String, dynamic>>[];
    for (final raw in all) {
      if (raw is! Map) {
        continue;
      }
      final m = Map<String, dynamic>.from(raw);
      if (m['isFinished'] == true) {
        continue;
      }
      if (!doctorSupervisesProject(m, doctorId)) {
        continue;
      }
      out.add(m);
    }
    out.sort((a, b) {
      final ya = '${a['academicYear'] ?? ''}';
      final yb = '${b['academicYear'] ?? ''}';
      final c = yb.compareTo(ya);
      if (c != 0) {
        return c;
      }
      return '${a['title'] ?? ''}'.compareTo('${b['title'] ?? ''}');
    });
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('مشاريع تحت إشرافي'),
        actions: [
          IconButton(
            tooltip: 'تحديث',
            onPressed: _reload,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('${snap.error}'));
          }
          final list = snap.data ?? [];
          if (list.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Text(
                  'لا توجد مشاريع غير مكتملة أنت مشرف عليها حالياً.\n'
                  'عند قبول الإشراف أو تعيينك مشرفاً يظهر المشروع هنا.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge,
                ),
              ),
            );
          }
          return RefreshIndicator.adaptive(
            onRefresh: () async {
              _reload();
              await Future<void>.delayed(const Duration(milliseconds: 60));
              await _future;
            },
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              itemCount: list.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final m = list[i];
                final id = m['_id']?.toString() ?? '';
                final title = m['title']?.toString() ?? 'مشروع';
                final year = m['academicYear']?.toString() ?? '';

                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      backgroundColor:
                          theme.colorScheme.primaryContainer.withValues(alpha: 0.85),
                      child: Icon(
                        Icons.folder_special_rounded,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    title: Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        year.isEmpty ? 'قيد العمل' : '$year · قيد العمل',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                    trailing: const Icon(Icons.chevron_left),
                    onTap: id.isEmpty
                        ? null
                        : () {
                            Navigator.of(context).push<void>(
                              MaterialPageRoute<void>(
                                builder: (_) =>
                                    DoctorProjectSupervisionHubScreen(projectId: id),
                              ),
                            );
                          },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
