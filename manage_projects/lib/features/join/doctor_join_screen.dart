import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/project_supervisor_label.dart';
import '../../data/grad_hub_api.dart';

/// قائمة طلبات الانضمام إلى مشاريع يشرف عليها الدكتور (طالب → مشرف يقبل/يرفض).
class DoctorJoinRequestsPanel extends StatefulWidget {
  const DoctorJoinRequestsPanel({super.key});

  @override
  State<DoctorJoinRequestsPanel> createState() => _DoctorJoinRequestsPanelState();
}

class _DoctorJoinRequestsPanelState extends State<DoctorJoinRequestsPanel> {
  Future<List<dynamic>>? _f;

  void _reload() {
    setState(() {
      _f = context.read<GradHubApi>().doctorJoinPending();
    });
  }

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _approve(String id) async {
    try {
      await context.read<GradHubApi>().doctorJoinApprove(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم قبول الطلب')),
        );
        _reload();
      }
    } on DioException catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${e.response?.data ?? e.message}')),
      );
    }
  }

  Future<void> _reject(String id) async {
    try {
      final r = await context.read<GradHubApi>().doctorJoinReject(id);
      if (!mounted) {
        return;
      }
      final blocked = r['blockedFromProject'] == true;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            blocked ? 'تم الرفض — قد يُحظر الطالب بعد تجاوز عدد الرفض.' : 'تم الرفض',
          ),
        ),
      );
      _reload();
    } on DioException catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${e.response?.data ?? e.message}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: _f,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Text('${snap.error}'));
        }
        final list = snap.data ?? [];
        if (list.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('لا توجد طلبات معلّقة لمشاريعك.'),
            ),
          );
        }
        return RefreshIndicator.adaptive(
          onRefresh: () async {
            _reload();
            await Future<void>.delayed(const Duration(milliseconds: 100));
            await _f;
          },
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 11),
            itemBuilder: (context, i) {
              final m = Map<String, dynamic>.from(list[i] as Map);
              final id = m['_id']?.toString() ?? '';
              final req =
                  Map<String, dynamic>.from((m['requester'] ?? {}) as Map);
              final proj =
                  Map<String, dynamic>.from((m['project'] ?? {}) as Map);
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'طالب يطلب الانضمام إلى مشروعك',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                      ),
                      Text(
                        proj['title']?.toString() ?? 'مشروع',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          'المشرفون المعروضون على المشروع: ${projectSupervisorsShortLabel(proj)}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                      if ((proj['description'] ?? '')
                          .toString()
                          .trim()
                          .isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          proj['description'].toString(),
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                      if (proj['isFinished'] == true)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'المشروع منجز (أرشيف)',
                            style:
                                Theme.of(context).textTheme.labelMedium?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .tertiary,
                                    ),
                          ),
                        ),
                      Builder(
                        builder: (context) {
                          final raw = m['teamMembersOnProject'];
                          if (raw is! List || raw.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          final buf = StringBuffer();
                          for (final e in raw) {
                            if (e is Map) {
                              final mm = Map<String, dynamic>.from(e);
                              buf.writeln(
                                '${mm['name'] ?? ''} · ${mm['uniNumber'] ?? ''}',
                              );
                            }
                          }
                          if (buf.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'طلاب مسجّلون على المشروع:',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  buf.toString().trim(),
                                  style:
                                      Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'الطالب: ${req['name'] ?? ''} · الرقم الجامعي ${req['uniNumber'] ?? ''}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: id.isEmpty ? null : () => _reject(id),
                              child: const Text('رفض'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FilledButton(
                              onPressed: id.isEmpty ? null : () => _approve(id),
                              child: const Text('قبول'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
