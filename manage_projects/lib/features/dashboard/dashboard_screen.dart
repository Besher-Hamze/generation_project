import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/mongo_ref.dart';
import '../../data/grad_hub_api.dart';
import '../../providers/auth_provider.dart';
import '../../core/widgets/app_logo.dart';
import '../projects/create_project_screen.dart';
import '../projects/edit_my_project_screen.dart';
import '../projects/project_detail_screen.dart';
import '../assistant/assistant_screen.dart';

/// لوحة تهيئة سريعة حسب الدور (UML: كل فاعل له مساره).
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, required this.role});

  final String role;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final name = auth.user?['name']?.toString() ?? '';
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppLogo(size: 32),
            const SizedBox(width: 12),
            const Text('مرشد'),
          ],
        ),
        actions: [
          if (role == 'doctor')
            IconButton(
              tooltip: 'تغيير كلمة السرّ',
              icon: const Icon(Icons.lock_reset_rounded),
              onPressed: () {
                showDialog<void>(
                  context: context,
                  builder: (_) => const _DoctorPasswordDialogBody(),
                );
              },
            ),
          IconButton(
            tooltip: 'تسجيل الخروج',
            onPressed: () async {
              await auth.logout();
            },
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'مرحباً، $name',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _tagline(
                      role,
                      auth.studentHasProject,
                      auth.studentCanRequestJoinToSupervisedProjects,
                    ),
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.92),
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 22),
                  if (role == 'student' && auth.studentHasProject)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: _StudentMyProjectCard(projectId: auth.studentProjectId!),
                    ),
                  _InsightStrip(role: role, auth: auth),
                  const SizedBox(height: 16),
                  Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: theme.colorScheme.tertiaryContainer
                            .withValues(alpha: 0.85),
                        child: Icon(
                          Icons.smart_toy_rounded,
                          color: theme.colorScheme.onTertiaryContainer,
                        ),
                      ),
                      title: const Text('مساعد مرشد'),
                      subtitle: const Text(
                        'شرح مختصر عن الانضمام، الإشراف، اللجان والجلسات.',
                      ),
                      trailing: const Icon(Icons.chevron_left),
                      onTap: () {
                        Navigator.of(context).push<void>(
                          MaterialPageRoute<void>(
                            builder: (_) => const AssistantScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (role == 'student' && !auth.studentHasProject)
                    FilledButton.tonalIcon(
                      onPressed: () {
                        Navigator.of(context).push<void>(
                          MaterialPageRoute(
                            builder: (_) => const CreateProjectScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add_circle_outline_rounded),
                      label: const Text('مشروع جديد'),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _tagline(String role, bool stuHasProj, bool canJoinOthers) {
    switch (role) {
      case 'admin':
        return 'لا تسجل جلسات من حساب الإدارة. أنشئ لجنة (اسم + دكاترة)، ثم وزّع مشاريع العام الحالي غير المكتملة على لجنة من «توزيع على اللجان». يظهر اسم اللجنة لطالب المشروع.';
      case 'doctor':
        return 'من «المراجعة»: طلبات الانضمام ودعوات الإشراف. من «الجلسات»: سجل المتابعات. علامة اللجنة النهائية تظهر داخل مشروع له لجنة.';
      default:
        if (!stuHasProj) {
          return 'يمكنك إنشاء مشروعك أو الانضمام لمشروع جاهز من تبويب «اكتشف».';
        }
        if (canJoinOthers && stuHasProj) {
          return 'مشروعك بلا مشرف بعد: ادعُ أساتذةً أو ابحث عن مشروع لمشرف موجود.';
        }
        return 'مشروعك أدناه — افتح التفاصيل أو تابع الجلسات من التبويبات.';
    }
  }
}

class _StudentMyProjectCard extends StatefulWidget {
  const _StudentMyProjectCard({required this.projectId});

  final String projectId;

  @override
  State<_StudentMyProjectCard> createState() => _StudentMyProjectCardState();
}

class _StudentMyProjectCardState extends State<_StudentMyProjectCard> {
  Future<Map<String, dynamic>>? _memo;

  void _bumpReload() => setState(() => _memo = null);

  @override
  void didUpdateWidget(covariant _StudentMyProjectCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.projectId != widget.projectId) {
      _memo = null;
    }
  }

  String _ellipsis(String raw, int maxChars) {
    final t = raw.trim();
    if (t.length <= maxChars) {
      return t;
    }
    return '${t.substring(0, maxChars)}…';
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف المشروع؟'),
        content: const Text(
          'يُحذف إن لم ينضم إليك أحد بعد. إذا ظهر خطأ من الخادم فمعناه لا يمكن الحذف الآن.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) {
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    final api = context.read<GradHubApi>();
    final auth = context.read<AuthProvider>();
    try {
      await api.deleteMyProject(widget.projectId);
      await auth.refreshMe();
      if (!context.mounted) {
        return;
      }
      messenger.showSnackBar(const SnackBar(content: Text('تم حذف المشروع.')));
    } on DioException catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('${e.response?.data ?? e.message}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final api = context.read<GradHubApi>();
    final auth = context.watch<AuthProvider>();

    final future =
        _memo ??= api.getProject(widget.projectId);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: FutureBuilder<Map<String, dynamic>>(
          future: future,
          builder: (context, snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const Center(
                heightFactor: 1.8,
                child: CircularProgressIndicator(),
              );
            }
            if (snap.hasError || snap.data == null) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'تعذّر تحميل مشروعك.',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${snap.error}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.tonal(
                    onPressed: _bumpReload,
                    child: const Text('إعادة المحاولة'),
                  ),
                ],
              );
            }
            final data = snap.data!;
            final rawTitle = (data['title']?.toString() ?? '').trim();
            final title =
                rawTitle.isEmpty ? 'بدون عنوان' : rawTitle;
            final year = data['academicYear']?.toString().trim();
            final desc = data['description']?.toString().trim();
            final createdId = mongoRefId(data['createdByStudent']);
            final imCreator =
                auth.studentUserId != null &&
                createdId == auth.studentUserId &&
                createdId != null;
            final finished = data['isFinished'] == true;

            final theme = Theme.of(context);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.folder_special_rounded,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'مشروعي',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    height: 1.25,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (year != null && year.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Chip(
                    visualDensity: VisualDensity.compact,
                    avatar: const Icon(Icons.calendar_month_rounded, size: 18),
                    label: Text(year),
                  ),
                ],
                if (desc != null && desc.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    _ellipsis(desc, 180),
                    style: theme.textTheme.bodyMedium?.copyWith(height: 1.48),
                  ),
                ],
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  alignment: WrapAlignment.end,
                  children: [
                    FilledButton.icon(
                      onPressed: () {
                        Navigator.of(context).push<void>(
                          MaterialPageRoute(
                            builder: (_) =>
                                ProjectDetailScreen(projectId: widget.projectId),
                          ),
                        ).then((_) => _bumpReload());
                      },
                      icon: const Icon(Icons.open_in_new_rounded),
                      label: const Text('التفاصيل الكاملة'),
                    ),
                    if (imCreator && !finished)
                      FilledButton.tonalIcon(
                        onPressed: () async {
                          final ok = await Navigator.of(context).push<bool>(
                            MaterialPageRoute<bool>(
                              builder: (_) =>
                                  EditMyProjectScreen(projectId: widget.projectId),
                            ),
                          );
                          if (ok == true && context.mounted) {
                            await context.read<AuthProvider>().refreshMe();
                            _bumpReload();
                          }
                        },
                        icon: const Icon(Icons.edit_rounded),
                        label: const Text('تعديل'),
                      ),
                    if (imCreator && !finished)
                      OutlinedButton.icon(
                        onPressed: () => _confirmDelete(context),
                        icon: Icon(
                          Icons.delete_outline_rounded,
                          color: theme.colorScheme.error,
                        ),
                        label: Text(
                          'حذف',
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                      ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _InsightStrip extends StatelessWidget {
  const _InsightStrip({required this.role, required this.auth});

  final String role;
  final AuthProvider auth;

  bool get hasProject => auth.studentHasProject;
  bool get canDraftJoin => auth.studentCanRequestJoinToSupervisedProjects;

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final tiles = switch (role) {
      'admin' => [
        _TileData('لجنة جديدة', 'اسم وأعضاء', Icons.groups_3_rounded),
        _TileData('توزيع', 'مشاريع العام', Icons.hub_rounded),
        _TileData('مشاريع', 'غير مكتملة هذا العام', Icons.folder_special_rounded),
      ],
      'doctor' => [
        _TileData('طلبات', 'انضمام + إشراف', Icons.fact_check_rounded),
        _TileData('إشرافي', 'غير مكتملة وجلسات', Icons.how_to_reg_rounded),
        _TileData('جلسات', 'كل الجلسات', Icons.star_rate_rounded),
      ],
      _ => [
        _TileData(
          'طلب الانضمام',
          (!hasProject || canDraftJoin) ? 'للمشاريع المعروضة' : 'تحت مشرف أكاديمي',
          Icons.person_add_alt_1_rounded,
        ),
        _TileData('الإشراف', 'دعوات للأساتذة', Icons.forward_to_inbox_rounded),
        _TileData('الجلسات', 'جدول المتابعة', Icons.event_available_rounded),
      ],
    };
    return Row(
      children: [
        for (var i = 0; i < tiles.length; i++) ...[
          Expanded(child: _MiniTile(tile: tiles[i], color: c)),
          if (i < tiles.length - 1) const SizedBox(width: 10),
        ],
      ],
    );
  }
}

class _TileData {
  _TileData(this.title, this.sub, this.icon);

  final String title;
  final String sub;
  final IconData icon;
}

class _MiniTile extends StatelessWidget {
  const _MiniTile({required this.tile, required this.color});

  final _TileData tile;
  final ColorScheme color;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(tile.icon, size: 22, color: color.primary),
            const SizedBox(height: 8),
            Text(
              tile.title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              tile.sub,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color.outline.withValues(alpha: 0.9),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DoctorPasswordDialogBody extends StatefulWidget {
  const _DoctorPasswordDialogBody();

  @override
  State<_DoctorPasswordDialogBody> createState() =>
      _DoctorPasswordDialogBodyState();
}

class _DoctorPasswordDialogBodyState extends State<_DoctorPasswordDialogBody> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _again = TextEditingController();
  bool _busy = false;
  String? _err;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _again.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final c = _current.text;
    final n = _next.text;
    final a = _again.text;
    if (n.length < 6) {
      setState(() => _err = 'كلمة سر جديدة لا تقل عن ٦ خانات.');
      return;
    }
    if (n != a) {
      setState(() => _err = 'التأكيد لا يطابق كلمة السر الجديدة.');
      return;
    }
    setState(() {
      _busy = true;
      _err = null;
    });
    try {
      await context.read<GradHubApi>().doctorChangePassword(
            currentPassword: c,
            newPassword: n,
          );
      if (!mounted) {
        return;
      }
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger.showSnackBar(
        const SnackBar(content: Text('تم تحديث كلمة السرّ')),
      );
    } on DioException catch (e) {
      setState(() {
        _busy = false;
        _err = e.response?.data?.toString() ?? e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('تغيير كلمة السرّ'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _current,
              obscureText: true,
              decoration:
                  const InputDecoration(labelText: 'كلمة السر الحالية'),
            ),
            TextField(
              controller: _next,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'الجديدة'),
            ),
            TextField(
              controller: _again,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'تكرار الجديدة'),
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
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: _busy ? null : _submit,
          child: _busy
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('حفظ'),
        ),
      ],
    );
  }
}
