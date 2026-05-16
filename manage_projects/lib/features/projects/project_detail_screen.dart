import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/utils/mongo_ref.dart';
import '../../data/grad_hub_api.dart';
import '../../providers/auth_provider.dart';
import 'edit_my_project_screen.dart';
import 'supervision_invite_screen.dart';

class ProjectDetailScreen extends StatefulWidget {
  const ProjectDetailScreen({super.key, required this.projectId});

  /// يُستخدم فقط في طلب الشبكة — لا يُعرَض للمستخدم.
  final String projectId;

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  int _reloadToken = 0;

  void _refreshProject() {
    setState(() => _reloadToken++);
  }

  @override
  Widget build(BuildContext context) {
    final api = context.read<GradHubApi>();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(title: const Text('تفاصيل المشروع')),
      body: FutureBuilder<Map<String, dynamic>>(
        key: ValueKey(_reloadToken),
        future: api.getProject(widget.projectId),
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
          final data = snap.data!;
          return _ProjectBody(
            data: data,
            projectId: widget.projectId,
            onProjectChanged: _refreshProject,
          );
        },
      ),
    );
  }
}

class _ProjectBody extends StatelessWidget {
  const _ProjectBody({
    required this.data,
    required this.projectId,
    required this.onProjectChanged,
  });

  final Map<String, dynamic> data;
  final String projectId;
  final VoidCallback onProjectChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = data['title']?.toString() ?? 'مشروع';
    final year = data['academicYear']?.toString() ?? '';
    final desc = data['description']?.toString() ?? '';
    final finished = data['isFinished'] == true;
    final mark = data['mark'];
    final supervisors = _doctorList(data);
    final supervisorNames = data['supervisorDisplayName']?.toString();
    final teamStudents = _teamStudents(data);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              if (year.isNotEmpty)
                Chip(
                  avatar: const Icon(Icons.calendar_month_rounded, size: 18),
                  label: Text(year),
                ),
              Chip(
                avatar: Icon(
                  finished ? Icons.check_circle_rounded : Icons.pending_rounded,
                  size: 18,
                  color: finished
                      ? theme.colorScheme.secondary
                      : theme.colorScheme.primary,
                ),
                label: Text(finished ? 'مكتمل' : 'قيد العمل'),
              ),
              if (mark != null && '$mark'.isNotEmpty)
                Chip(
                  avatar: const Icon(Icons.star_rounded, size: 18),
                  label: Text('العلامة: $mark'),
                ),
            ],
          ),
          _OwnerManageProjectRow(
            data: data,
            projectId: projectId,
            onAfterEdit: onProjectChanged,
          ),
          if (desc.isNotEmpty) ...[
            const SizedBox(height: 22),
            Text(
              'نبذة المشروع',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              desc,
              style: theme.textTheme.bodyLarge?.copyWith(height: 1.55),
            ),
          ],
          const SizedBox(height: 22),
          _SectionTitle(icon: Icons.groups_rounded, text: 'فريق الطلاب'),
          if (teamStudents.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6, bottom: 4),
              child: Text(
                'لا يوجد طلاب مرتبطون بهذا المشروع في السجّل حالياً.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.outline,
                  height: 1.45,
                ),
              ),
            )
          else
            ...teamStudents.map((m) => _StudentMemberTile(map: m)),
          _CommitteeSection(data: data),
          if ((supervisorNames ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 20),
            _SectionTitle(icon: Icons.badge_rounded, text: 'أسماء المشرفين (من المصدر)'),
            Text(
              supervisorNames!,
              style: theme.textTheme.bodyLarge,
            ),
          ],
          if (supervisors.isNotEmpty) ...[
            const SizedBox(height: 22),
            _SectionTitle(
              icon: Icons.school_rounded,
              text: 'الإشراف الأكاديمي',
            ),
            ...supervisors.map((d) => _DoctorTile(map: d)),
          ],
          if (context.read<AuthProvider>().role == 'doctor' &&
              (mongoRefId(data['committees']) ?? '').isNotEmpty) ...[
            const SizedBox(height: 18),
            _DoctorCommitteeFinalMarkPanel(
              projectId: projectId,
              onSaved: onProjectChanged,
            ),
          ],
          const SizedBox(height: 20),
          _OwnerInviteSupervisorsRow(
            data: data,
            projectId: projectId,
          ),
          const SizedBox(height: 16),
          _OwnerTeamEnrollmentPanel(
            data: data,
            projectId: projectId,
            onSaved: onProjectChanged,
          ),
          if (context.read<AuthProvider>().role == 'student') ...[
            const SizedBox(height: 28),
            _StudentJoinActions(
              projectPayload: data,
              projectId: projectId,
            ),
          ],
        ],
      ),
    );
  }

  /// دمج المشرف الرئيسي + قائمة المشرفين دون تكرار (بدون أي معرفات).
  static List<Map<String, dynamic>> _doctorList(Map<String, dynamic> data) {
    final out = <Map<String, dynamic>>[];
    void add(dynamic raw) {
      if (raw is! Map) {
        return;
      }
      final m = Map<String, dynamic>.from(raw);
      final hasName =
          (m['name']?.toString().isNotEmpty == true) ||
          (m['email']?.toString().isNotEmpty == true);
      if (!hasName) {
        return;
      }
      if (out.any((e) =>
          e['name'] == m['name'] && e['email'] == m['email'])) {
        return;
      }
      out.add(m);
    }

    add(data['supervisor']);
    final ss = data['supervisors'];
    if (ss is List) {
      for (final x in ss) {
        add(x);
      }
    }
    return out;
  }

  static List<Map<String, dynamic>> _teamStudents(Map<String, dynamic> data) {
    final raw = data['teamStudents'];
    if (raw is! List) {
      return [];
    }
    final out = <Map<String, dynamic>>[];
    for (final x in raw) {
      if (x is Map) {
        out.add(Map<String, dynamic>.from(x));
      }
    }
    return out;
  }
}

/// لجنة المناقشة المعروضة للطالب وفريق العمل بعد التوزيع من الإدارة.
class _CommitteeSection extends StatelessWidget {
  const _CommitteeSection({required this.data});

  final Map<String, dynamic> data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final role = context.read<AuthProvider>().role;
    final cid = mongoRefId(data['committees']);
    if (cid != null && cid.isNotEmpty) {
      final c = data['committees'];
      var label = 'لجنة';
      if (c is Map) {
        final l = c['label']?.toString().trim();
        if (l != null && l.isNotEmpty) {
          label = l;
        }
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          _SectionTitle(
            icon: Icons.how_to_vote_rounded,
            text: 'لجنة المشروع / المناقشة',
          ),
          Card(
            color: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.45),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor:
                    theme.colorScheme.tertiary.withValues(alpha: 0.25),
                child: Icon(
                  Icons.groups_rounded,
                  color: theme.colorScheme.onTertiaryContainer,
                ),
              ),
              title: Text(
                label,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              subtitle: Text(
                'عيّنتها الإدارة لهذا المشروع — يظهر الاسم لك وللفريق.',
                style: theme.textTheme.bodySmall?.copyWith(height: 1.35),
              ),
            ),
          ),
        ],
      );
    }
    if (role == 'student') {
      return Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Text(
          'لم تُعيَّن بعد لجنة مناقشة لهذا المشروع. ستظهر اسم اللجنة هنا بعد التوزيع من الإدارة.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.outline,
            height: 1.45,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }
    return const SizedBox.shrink();
  }
}

class _StudentMemberTile extends StatelessWidget {
  const _StudentMemberTile({required this.map});

  final Map<String, dynamic> map;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = (map['name']?.toString() ?? '').trim();
    final uni = (map['uniNumber']?.toString() ?? '').trim();
    final leader = map['isTeamLeader'] == true;
    final displayName = name.isEmpty ? 'طالب' : name;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          foregroundColor: theme.colorScheme.onPrimaryContainer,
          child: Text(
            _firstVisibleChar(displayName),
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        title: Text(
          displayName,
          style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        subtitle: uni.isNotEmpty
            ? Text('الرقم الجامعي: $uni', style: theme.textTheme.bodySmall)
            : null,
        trailing: leader
            ? Chip(
                visualDensity: VisualDensity.compact,
                label: const Text('قائد الفريق'),
                avatar: Icon(
                  Icons.star_rounded,
                  size: 18,
                  color: theme.colorScheme.primary,
                ),
              )
            : null,
      ),
    );
  }
}

/// أول محرف ظاهر لاسم قد يكون عربياً؛ بدون اعتماد على حزمة `characters`.
String _firstVisibleChar(String raw) {
  final s = raw.trim();
  if (s.isEmpty) {
    return '?';
  }
  return String.fromCharCode(s.runes.first);
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 22, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            text,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _DoctorTile extends StatelessWidget {
  const _DoctorTile({required this.map});

  final Map<String, dynamic> map;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = map['name']?.toString() ?? 'مشرف';
    final email = map['email']?.toString();
    final office = map['officeNo']?.toString();
    final phone = map['phone']?.toString();

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name, style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                )),
            if (email != null && email.isNotEmpty && !email.endsWith('@seed.local'))
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(email, style: theme.textTheme.bodyMedium),
              ),
            if (office != null && office.trim().isNotEmpty && office != '—')
              Text(
                'المكتب: $office',
                style: theme.textTheme.bodySmall,
              ),
            if (phone != null && phone.trim().isNotEmpty && phone != '—')
              Text(
                'الهاتف: $phone',
                style: theme.textTheme.bodySmall,
              ),
          ],
        ),
      ),
    );
  }
}

/// تعديل / حذف المشروع لمنشئه فقط (قبل إنهاء المشروع).
class _OwnerManageProjectRow extends StatelessWidget {
  const _OwnerManageProjectRow({
    required this.data,
    required this.projectId,
    required this.onAfterEdit,
  });

  final Map<String, dynamic> data;
  final String projectId;
  final VoidCallback onAfterEdit;

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف المشروع؟'),
        content: const Text(
          'يُحذف إن كان أنت وحيداً في الفريق. إذا انضم طالب آخر لا يمكن الحذف من هنا.',
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
    if (confirmed != true || !context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final api = context.read<GradHubApi>();
    final authProv = context.read<AuthProvider>();
    try {
      await api.deleteMyProject(projectId);
      await authProv.refreshMe();
      if (!context.mounted) return;
      messenger.showSnackBar(const SnackBar(content: Text('تم حذف المشروع.')));
      Navigator.of(context).pop();
    } on DioException catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('${e.response?.data ?? e.message}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (auth.role != 'student') {
      return const SizedBox.shrink();
    }
    final myId = auth.studentUserId;
    final creatorId = mongoRefId(data['createdByStudent']);
    if (myId == null ||
        creatorId == null ||
        creatorId != myId ||
        data['isFinished'] == true) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Card(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'مشروعي',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                alignment: WrapAlignment.end,
                children: [
                  FilledButton.tonalIcon(
                    onPressed: () async {
                            final ok =
                                await Navigator.of(context).push<bool>(
                              MaterialPageRoute<bool>(
                                builder: (_) => EditMyProjectScreen(
                                  projectId: projectId,
                                ),
                              ),
                            );
                            if (ok == true && context.mounted) {
                              onAfterEdit();
                              await context.read<AuthProvider>().refreshMe();
                            }
                          },
                    icon: const Icon(Icons.edit_note_rounded),
                    label: const Text('تعديل العنوان والوصف'),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _confirmDelete(context),
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      color: Theme.of(context).colorScheme.error,
                    ),
                    label: Text(
                      'حذف المشروع',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OwnerInviteSupervisorsRow extends StatelessWidget {
  const _OwnerInviteSupervisorsRow({
    required this.data,
    required this.projectId,
  });

  final Map<String, dynamic> data;
  final String projectId;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (auth.role != 'student') {
      return const SizedBox.shrink();
    }
    final myId = auth.studentUserId;
    final creatorId = mongoRefId(data['createdByStudent']);
    if (myId == null || creatorId == null || creatorId != myId) {
      return const SizedBox.shrink();
    }
    if (data['isFinished'] == true) {
      return const SizedBox.shrink();
    }
    if (!auth.canInviteSupervisors) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.tonalIcon(
          onPressed: () async {
            await Navigator.of(context).push<bool>(
              MaterialPageRoute<bool>(
                builder: (_) => SupervisionInviteScreen(projectId: projectId),
              ),
            );
          },
          icon: const Icon(Icons.outgoing_mail),
          label: const Text('دعوة أساتذة للإشراف (أول قبول يثبّت المشرف)'),
        ),
        const SizedBox(height: 8),
        Text(
          'يُنصح باختيار أكثر من أستاذ؛ من يقبل أولاً يربط المشروع به ويُلغى الباقي تلقائياً.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _OwnerTeamEnrollmentPanel extends StatefulWidget {
  const _OwnerTeamEnrollmentPanel({
    required this.data,
    required this.projectId,
    required this.onSaved,
  });

  final Map<String, dynamic> data;
  final String projectId;
  final VoidCallback onSaved;

  @override
  State<_OwnerTeamEnrollmentPanel> createState() =>
      _OwnerTeamEnrollmentPanelState();
}

class _OwnerTeamEnrollmentPanelState extends State<_OwnerTeamEnrollmentPanel> {
  late bool _open;
  late int _max;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final d = widget.data;
    _open = d['enrollmentOpen'] != false;
    final raw = d['maxTeamMembers'];
    var m = 2;
    if (raw == null || raw == 'null') {
      m = 2;
    } else if (raw is num) {
      m = raw.toInt().clamp(1, 50);
    }
    _max = m;
  }

  @override
  void didUpdateWidget(covariant _OwnerTeamEnrollmentPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
      final d = widget.data;
      _open = d['enrollmentOpen'] != false;
      final raw = d['maxTeamMembers'];
      if (raw == null || raw == 'null') {
        _max = 2;
      } else if (raw is num) {
        _max = raw.toInt().clamp(1, 50);
      }
    }
  }

  Future<void> _saveEnrollmentOnly() async {
    setState(() => _busy = true);
    try {
      await context.read<GradHubApi>().patchMyProjectTeamEnrollment(
            widget.projectId,
            enrollmentOpen: _open,
          );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_open ? 'تم فتح قبول انضمام لفريقك.' : 'تم إغلاق الانتساب لهذا المشروع.')),
      );
      widget.onSaved();
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${e.response?.data ?? e.message}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _saveMax() async {
    setState(() => _busy = true);
    try {
      await context.read<GradHubApi>().patchMyProjectTeamEnrollment(
            widget.projectId,
            maxTeamMembers: _max,
          );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تحديث الحد الأقصى لعدد الطلاب.')),
      );
      widget.onSaved();
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${e.response?.data ?? e.message}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (auth.role != 'student') {
      return const SizedBox.shrink();
    }
    final myId = auth.studentUserId;
    final creatorId = mongoRefId(widget.data['createdByStudent']);
    if (myId == null || creatorId == null || creatorId != myId) {
      return const SizedBox.shrink();
    }
    final finished = widget.data['isFinished'] == true;
    if (finished) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'المشروع منجز — لا يمكن تعديل إعدادات الانتساب.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'إدارة فريق الطلاب',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'الحد الافتراضي طالباتان على المشروع (أنت + زميل). يمكنك إغلاق قبول انضمام جديد عندما يكتمل الفريق.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('قبول طلبات انضمام لفريقي'),
              subtitle: Text(_open ? 'مفتوح للطلاب من «اكتشف»' : 'مغلق — لا طلبات جديدة'),
              value: _open,
              onChanged: _busy
                  ? null
                  : (v) {
                      setState(() => _open = v);
                      _saveEnrollmentOnly();
                    },
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    'عدد الطلاب الأقصى (بما فيك أنت): $_max',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                IconButton(
                  tooltip: 'خفض',
                  onPressed:
                      _busy || _max <= 1 ? null : () => setState(() => _max--),
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                IconButton(
                  tooltip: 'رفع',
                  onPressed: _busy || _max >= 50
                      ? null
                      : () => setState(() => _max++),
                  icon: const Icon(Icons.add_circle_outline),
                ),
                FilledButton(
                  onPressed: _busy ? null : _saveMax,
                  child: const Text('حفظ العدد'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// زر الانضمام للطالب: إما لفريق مشروع طالب أو لمشروع بمشرف أكاديمي.
class _StudentJoinActions extends StatelessWidget {
  const _StudentJoinActions({
    required this.projectPayload,
    required this.projectId,
  });

  final Map<String, dynamic> projectPayload;
  final String projectId;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (auth.role != 'student') {
      return const SizedBox.shrink();
    }

    final myId = auth.studentUserId;
    final cid = mongoRefId(projectPayload['createdByStudent']);
    final isStudentLed = cid != null;
    final mine = auth.studentProjectId == projectId;
    final canRequest = auth.studentCanRequestJoinToSupervisedProjects;
    final blocked = auth.projectIsBlocked(projectId);
    final finishedProject = projectPayload['isFinished'] == true;

    final isOwner = myId != null && isStudentLed && myId == cid;
    final onTeamNotOwner =
        mine && isStudentLed && myId != null && myId != cid;

    if (mine && isStudentLed && isOwner) {
      if (canRequest) {
        return Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            'أنت قائد هذا الفريق — راجع «انضمام» › «وارد الفريق» لقبول أو رفض طلبات الانضمام.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        );
      }
      return Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          'أنت قائد هذا المشروع وهو تحت مشرف أكاديمي — تابع الطلبات من تبويب «انضمام».',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      );
    }

    if (onTeamNotOwner) {
      return Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          'أنت ضمن فريق هذا المشروع بالفعل.',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      );
    }

    if (mine && !isStudentLed && canRequest) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context)
              .colorScheme
              .surfaceContainerHighest
              .withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color:
                Theme.of(context).colorScheme.outline.withValues(alpha: 0.25),
          ),
        ),
        child: Text(
          'مسوّدة مشروعك لا تصلح لطلب انضمام لفريق هنا. من «اكتشف» اختر مشروع فريق طلاب أو مشروعاً بأستاذ مشرف.',
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      );
    }

    if (!canRequest) {
      return Text(
        'وضعك الحالي لا يسمح بإرسال طلب انضمام لفريق أو مشروع آخر.',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
        textAlign: TextAlign.center,
      );
    }

    if (blocked) {
      return Text(
        'لا يمكنك إرسال طلب لهذا المشروع بعد عدة رفض من قائد الفريق.',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
        textAlign: TextAlign.center,
      );
    }

    if (finishedProject) {
      return Text(
        'مشروع منجز (أرشيف) — لا يُقبل طلب انضمام جديد.',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
        textAlign: TextAlign.center,
      );
    }

    final peerClosed =
        isStudentLed && projectPayload['enrollmentOpen'] == false;
    if (peerClosed && !isOwner && !onTeamNotOwner) {
      return Text(
        'قائد الفريق أوقف قبول طلبات انضمام جديدة.',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
        textAlign: TextAlign.center,
      );
    }

    if (isStudentLed && myId != null && myId != cid) {
      return FilledButton.icon(
        onPressed: () => _sendPeer(context),
        icon: const Icon(Icons.group_add_rounded),
        label: const Text('طلب الانضمام لفريق هذا المشروع (موافقة صاحبه)'),
      );
    }

    /// مشروع بمشرف أكاديمي: طالب يطلب الانضمام فقط لمشروع **غير** مسجَّل هو عليه الآن؛
    /// مراسلة الدكاترة كمشرفين تتم من «دعوة أساتذة» لمشروعه هو فقط (`_OwnerInviteSupervisorsRow`).
    if (!isStudentLed && !mine) {
      return FilledButton.icon(
        onPressed: () => _sendDoctorSupervised(context),
        icon: const Icon(Icons.outgoing_mail),
        label: const Text('طلب الانضمام — للأستاذ المشرف'),
      );
    }

    return const SizedBox.shrink();
  }

  Future<void> _sendDoctorSupervised(BuildContext context) async {
    if (context.read<AuthProvider>().role != 'student') {
      return;
    }
    try {
      await context.read<GradHubApi>().joinRequestCreate(projectId);
      if (!context.mounted) {
        return;
      }
      await context.read<AuthProvider>().refreshMe();
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم الإرسال للمشرف الأكاديمي.')),
      );
    } on DioException catch (e) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${e.response?.data ?? e.message}')),
      );
    }
  }

  Future<void> _sendPeer(BuildContext context) async {
    if (context.read<AuthProvider>().role != 'student') {
      return;
    }
    try {
      await context.read<GradHubApi>().peerTeamJoinCreate(projectId);
      if (!context.mounted) {
        return;
      }
      await context.read<AuthProvider>().refreshMe();
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم الإرسال. سيقرّر قائد الفريق قبول أو رفض الطلب.'),
        ),
      );
    } on DioException catch (e) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${e.response?.data ?? e.message}')),
      );
    }
  }
}

/// عضو لجنة: تسجيل العلامة النهائية (٠–١٠٠) بعد المناقشة — يتحقق الخادم من العضوية.
class _DoctorCommitteeFinalMarkPanel extends StatefulWidget {
  const _DoctorCommitteeFinalMarkPanel({
    required this.projectId,
    required this.onSaved,
  });

  final String projectId;
  final VoidCallback onSaved;

  @override
  State<_DoctorCommitteeFinalMarkPanel> createState() =>
      _DoctorCommitteeFinalMarkPanelState();
}

class _DoctorCommitteeFinalMarkPanelState
    extends State<_DoctorCommitteeFinalMarkPanel> {
  final _markCtrl = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _markCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit(BuildContext context) async {
    final v = int.tryParse(_markCtrl.text.trim());
    if (v == null || v < 0 || v > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('أدخل علامة بين ٠ و ١٠٠.')),
      );
      return;
    }
    setState(() => _busy = true);
    try {
      await context.read<GradHubApi>().defenseFinalMark(widget.projectId, v);
      if (!context.mounted) {
        return;
      }
      widget.onSaved();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تسجيل علامة اللجنة.')),
      );
    } on DioException catch (e) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${e.response?.data ?? e.message}')),
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.how_to_vote_rounded,
                    color: theme.colorScheme.tertiary),
                const SizedBox(width: 8),
                Text(
                  'علامة اللجنة (بعد المناقشة)',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'يظهر هذا الحقل للدكتور عند تعيين لجنة للمشروع. إذا لم تكن عضواً في اللجنة فسيظهر خطأ توضّحه الرسالة.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _markCtrl,
              enabled: !_busy,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'العلامة (٠–١٠٠)',
              ),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: FilledButton(
                onPressed: _busy ? null : () => _submit(context),
                child: _busy
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('حفظ علامة اللجنة'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

