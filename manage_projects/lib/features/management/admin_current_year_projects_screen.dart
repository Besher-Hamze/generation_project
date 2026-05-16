import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/academic_year.dart';
import '../../data/grad_hub_api.dart';
import '../projects/project_detail_screen.dart';

/// للإدارة: مشاريع **العام الدراسي الحالي** غير المكتملة (عرض فقط).
class AdminCurrentYearProjectsScreen extends StatefulWidget {
  const AdminCurrentYearProjectsScreen({super.key});

  @override
  State<AdminCurrentYearProjectsScreen> createState() =>
      _AdminCurrentYearProjectsScreenState();
}

class _AdminCurrentYearProjectsScreenState
    extends State<AdminCurrentYearProjectsScreen> {
  Future<List<Map<String, dynamic>>>? _future;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reload());
  }

  void _reload() {
    setState(() {
      _future = _load(context.read<GradHubApi>());
    });
  }

  static Future<List<Map<String, dynamic>>> _load(GradHubApi api) async {
    final raw = await api.getList('/projects');
    final list = raw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .where(projectMatchesActiveAcademicYearAndNotFinished)
        .toList()
      ..sort((a, b) {
        final ta = '${a['title'] ?? ''}';
        final tb = '${b['title'] ?? ''}';
        return ta.compareTo(tb);
      });
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final y = activeAcademicYearLabelForNow();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('مشاريع العام الحالي'),
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
                  'لا مشاريع «قيد العمل» للعام $y.\n'
                  '(تأكد أن حقل academicYear في المشروع يطابق $y.)',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge,
                ),
              ),
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline,
                            color: theme.colorScheme.primary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'عرض فقط — العام $y، غير مكتملة. التوزيع على اللجان من «البيانات → توزيع على اللجان».',
                            style: theme.textTheme.bodySmall?.copyWith(
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: RefreshIndicator.adaptive(
                  onRefresh: () async {
                    _reload();
                    await Future<void>.delayed(
                      const Duration(milliseconds: 60),
                    );
                    await _future;
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                    itemCount: list.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final m = list[i];
                      final id = m['_id']?.toString() ?? '';
                      final title = m['title']?.toString() ?? 'مشروع';
                      final year = m['academicYear']?.toString() ?? '';
                      final c = m['committees'];
                      String committeeLine = '';
                      if (c is Map && c['label'] != null) {
                        committeeLine = c['label'].toString();
                      }

                      return Card(
                        child: ListTile(
                          title: Text(title,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              )),
                          subtitle: Text(
                            [
                              if (year.isNotEmpty) year,
                              if (committeeLine.isNotEmpty)
                                'اللجنة: $committeeLine'
                              else
                                'بدون لجنة بعد',
                            ].join(' · '),
                          ),
                          trailing: const Icon(Icons.chevron_left),
                          onTap: id.isEmpty
                              ? null
                              : () {
                                  Navigator.of(context).push<void>(
                                    MaterialPageRoute<void>(
                                      builder: (_) => ProjectDetailScreen(
                                        projectId: id,
                                      ),
                                    ),
                                  );
                                },
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
}
