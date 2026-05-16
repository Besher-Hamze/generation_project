import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/mongo_ref.dart';
import '../../data/grad_hub_api.dart';
import '../projects/project_detail_screen.dart';

/// دعوات إشراف واردة لحساب الدكتور (أول قبول يربط المشروع به).
class DoctorSupervisionInvitationsPanel extends StatefulWidget {
  const DoctorSupervisionInvitationsPanel({super.key});

  @override
  State<DoctorSupervisionInvitationsPanel> createState() =>
      _DoctorSupervisionInvitationsPanelState();
}

class _DoctorSupervisionInvitationsPanelState
    extends State<DoctorSupervisionInvitationsPanel> {
  Future<List<dynamic>>? _f;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _f = context.read<GradHubApi>().supervisionDoctorPending();
    });
  }

  Future<void> _accept(String id) async {
    try {
      await context.read<GradHubApi>().supervisionAccept(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم قبول الإشراف على المشروع')),
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
      await context.read<GradHubApi>().supervisionReject(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم رفض الدعوة')),
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
              child: Text('لا توجد دعوات إشراف معلّقة.'),
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
              final proj =
                  Map<String, dynamic>.from((m['project'] ?? {}) as Map);
              final st =
                  Map<String, dynamic>.from((m['studentOwner'] ?? {}) as Map);
              final projectIdStr = mongoRefId(m['project']);
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'دعوة إشراف من طالب',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: Theme.of(context).colorScheme.secondary,
                            ),
                      ),
                      Text(
                        proj['title']?.toString() ?? 'مشروع',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'الطالب: ${st['name'] ?? ''} · ${st['uniNumber'] ?? ''}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      if ((proj['description'] ?? '')
                          .toString()
                          .trim()
                          .isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          proj['description'].toString(),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                      if (projectIdStr != null && projectIdStr.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: TextButton.icon(
                            onPressed: () {
                              Navigator.of(context).push<void>(
                                MaterialPageRoute<void>(
                                  builder: (_) =>
                                      ProjectDetailScreen(projectId: projectIdStr),
                                ),
                              );
                            },
                            icon: const Icon(Icons.open_in_full_rounded, size: 20),
                            label: const Text('عرض تفاصيل المشروع كاملة'),
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed:
                                  id.isEmpty ? null : () => _reject(id),
                              child: const Text('رفض'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FilledButton(
                              onPressed:
                                  id.isEmpty ? null : () => _accept(id),
                              child: const Text('قبول الإشراف'),
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
