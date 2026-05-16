import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/project_supervisor_label.dart';
import '../../data/grad_hub_api.dart';
import '../../providers/auth_provider.dart';
import '../projects/projects_discover_screen.dart';

Map<String, dynamic> _dynMap(dynamic v) {
  if (v == null || v == 'null') {
    return <String, dynamic>{};
  }
  if (v is Map<String, dynamic>) {
    return v;
  }
  if (v is Map) {
    return Map<String, dynamic>.from(v);
  }
  return <String, dynamic>{};
}

class StudentJoinScreen extends StatefulWidget {
  const StudentJoinScreen({super.key});

  @override
  State<StudentJoinScreen> createState() => _StudentJoinScreenState();
}

class _StudentJoinScreenState extends State<StudentJoinScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _openProjectsCatalog() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const ProjectsDiscoverScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('الانضمام والطلبات'),
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          tabs: const [
            Tab(text: 'للمشاريع'),
            Tab(text: 'للدكاترة'),
            Tab(text: 'على مشروعي'),
            Tab(text: 'المشرف'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openProjectsCatalog,
        icon: const Icon(Icons.folder_open_rounded),
        label: const Text('معرض المشاريع'),
      ),
      body: TabBarView(
        controller: _tabs,
        children: const [
          _OutgoingProjectRequestsTab(),
          _SupervisionInvitesTab(),
          _IncomingOnMyProjectTab(),
          _MySupervisorTab(),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 26, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.message, this.icon = Icons.inbox_outlined});

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Icon(icon, color: theme.colorScheme.outline, size: 28),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// طلبات انضمام أرسلتها: (١) لمشروع يشرف عليه دكتور (٢) لفريق طالب.
class _OutgoingProjectRequestsTab extends StatefulWidget {
  const _OutgoingProjectRequestsTab();

  @override
  State<_OutgoingProjectRequestsTab> createState() =>
      _OutgoingProjectRequestsTabState();
}

class _OutgoingProjectRequestsTabState extends State<_OutgoingProjectRequestsTab> {
  Future<({List<dynamic> joins, List<dynamic> peers})>? _f;
  int _appliedSessionRev = -1;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final rev = context.watch<AuthProvider>().sessionRevision;
    if (rev != _appliedSessionRev) {
      _appliedSessionRev = rev;
      _reload();
    }
  }

  void _reload() {
    if (!mounted) {
      return;
    }
    if (!context.read<AuthProvider>().isAuthenticated) {
      return;
    }
    final api = context.read<GradHubApi>();
    setState(() {
      _f = () async {
        final joins = await api.joinOutgoing();
        final peers = await api.peerTeamOutgoing();
        return (joins: joins, peers: peers);
      }();
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<({List<dynamic> joins, List<dynamic> peers})>(
      future: _f,
      builder: (context, snap) {
        if (_f == null || snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('${snap.error}', textAlign: TextAlign.center),
          ));
        }
        final joins = snap.data?.joins ?? [];
        final peers = snap.data?.peers ?? [];

        return RefreshIndicator.adaptive(
          onRefresh: () async {
            _reload();
            final fut = _f;
            if (fut != null) await fut;
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 112),
            children: [
              _SectionHeader(
                icon: Icons.school_rounded,
                title: 'طلبات لمشاريع يشرف عليها أستاذ',
                subtitle:
                    'مرّ أستاذك المشرف قبل قبول الانضمام. تظهر هنا كل الطلبات التي أرسلتها لمثل هذه المشاريع.',
              ),
              if (joins.isEmpty)
                const _EmptyHint(
                  message:
                      'لا طلبات حالياً. من «معرض المشاريع» افتح مشروعاً فيه مشرف أكاديمي واضغط طلب الانضمام.',
                )
              else
                ...joins.map((raw) => _DoctorJoinTile(map: _dynMap(raw))),
              _SectionHeader(
                icon: Icons.groups_2_outlined,
                title: 'طلبات لفريق طلّاب',
                subtitle:
                    'مشروع أُنشِئ من زميل؛ قرار القبول من قائد الفريق وليس من تبويب الدكاترة.',
              ),
              if (peers.isEmpty)
                const _EmptyHint(
                  message:
                      'لم ترسل بعد طلباً لانضمام لفريق طالب. هذه ليست دعوة لأستاذ — ستظهر الدعوات للأساتذة في التبويب «للدكاترة».',
                  icon: Icons.group_add_outlined,
                )
              else
                ...peers.map((raw) => _PeerOutgoingTile(map: _dynMap(raw))),
            ],
          ),
        );
      },
    );
  }
}

class _DoctorJoinTile extends StatelessWidget {
  const _DoctorJoinTile({required this.map});

  final Map<String, dynamic> map;

  static String statusLabel(String s) => switch (s) {
        'pending' => 'قيد مراجعة المشرف',
        'accepted' => 'مقبول',
        'cancelled' => 'أُغلق تلقائياً (قُبِل طلب آخر)',
        'rejected' => 'مرفوض',
        _ => s,
      };

  @override
  Widget build(BuildContext context) {
    final st = map['status']?.toString() ?? '';
    final proj = _dynMap(map['project']);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        isThreeLine: true,
        title: Text(
          proj['title']?.toString().isNotEmpty == true
              ? proj['title']!.toString()
              : 'مشروع',
        ),
        subtitle: Text(
          'الحالة: ${statusLabel(st)}\nالمشرفون: ${projectSupervisorsShortLabel(proj)}',
        ),
      ),
    );
  }
}

class _PeerOutgoingTile extends StatelessWidget {
  const _PeerOutgoingTile({required this.map});

  final Map<String, dynamic> map;

  static String statusLabel(String s) => switch (s) {
        'pending' => 'بانتظار قائد الفريق',
        'accepted' => 'مقبول',
        'cancelled' => 'أُلغي تلقائياً',
        'rejected' => 'مرفوض',
        _ => s,
      };

  @override
  Widget build(BuildContext context) {
    final st = map['status']?.toString() ?? '';
    final proj = _dynMap(map['project']);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        isThreeLine: true,
        title: Text(
          proj['title']?.toString().isNotEmpty == true
              ? proj['title']!.toString()
              : 'مشروع فريق',
        ),
        subtitle: Text('الحالة: ${statusLabel(st)}'),
      ),
    );
  }
}

/// دعوات إشراف أرسلتها أنت للدكاترة (ليست طلب انضمام لمشروعهم الجاهز).
class _SupervisionInvitesTab extends StatefulWidget {
  const _SupervisionInvitesTab();

  @override
  State<_SupervisionInvitesTab> createState() => _SupervisionInvitesTabState();
}

class _SupervisionInvitesTabState extends State<_SupervisionInvitesTab> {
  Future<List<dynamic>>? _f;
  int _appliedSessionRev = -1;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final rev = context.watch<AuthProvider>().sessionRevision;
    if (rev != _appliedSessionRev) {
      _appliedSessionRev = rev;
      _reload();
    }
  }

  void _reload() {
    if (!mounted) return;
    if (!context.read<AuthProvider>().isAuthenticated) return;
    setState(() {
      _f = context.read<GradHubApi>().supervisionOutgoing();
    });
  }

  static String supervisionLabel(String s) => switch (s) {
        'pending' => 'لم يقرّ الدكتور بعد',
        'accepted' => 'قُبل — أصبح مشرفاً',
        'rejected' => 'رفض الدعوة',
        'cancelled' => 'أُلغيت (قُبل أستاذ آخر أو أُغلق الطلب)',
        _ => s,
      };

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return FutureBuilder<List<dynamic>>(
      future: _f,
      builder: (context, snap) {
        if (_f == null || snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Text('${snap.error}'));
        }
        final list = snap.data ?? [];
        return RefreshIndicator.adaptive(
          onRefresh: () async {
            _reload();
            final fut = _f;
            if (fut != null) await fut;
          },
          child: list.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 112),
                  children: [
                    _SectionHeader(
                      icon: Icons.outgoing_mail,
                      title: 'دعوات للأساتذة لإشراف مشروعك',
                      subtitle:
                          'هنا تظهر الدعوات التي أرسَلتها من شاشة «تفاصيل مشروعك» › دعوة أساتذة — وليست طلبات الانضمام لمشاريع جاهزة في المعرض.',
                    ),
                    _EmptyHint(
                      message: auth.canInviteSupervisors
                          ? 'لا دعوات بعد. ادخل «تفاصيل مشروعك» واختر أساتذةً لاستقبال دعواتهم هنا.'
                          : 'متاح لمشروعك كقائد فريق ولم يُثبَّت مشرف بعد. أو أنت ضمن مشروع بمشرف فعلي لا يحتاج دعوات من هنا.',
                    ),
                  ],
                )
              : ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 112),
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final m = _dynMap(list[i]);
                    final st = m['status']?.toString() ?? '';
                    final doc = _dynMap(
                      m['invitedDoctor'] ?? m['invitedDoctorId'],
                    );
                    final proj = _dynMap(m['project']);
                    final professor =
                        doc['name']?.toString().trim().isNotEmpty == true
                            ? doc['name']!.toString()
                            : 'أستاذ (اسم غير متوفر)';
                    final email = doc['email']?.toString();
                    final projectTitle =
                        proj['title']?.toString().trim().isNotEmpty == true
                            ? proj['title']!.toString()
                            : 'مشروعك';
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              professor,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            if (email != null &&
                                email.isNotEmpty &&
                                !email.endsWith('@seed.local'))
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  email,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                            const SizedBox(height: 8),
                            Text(
                              'المشروع: $projectTitle',
                              style:
                                  Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'الحالة: ${supervisionLabel(st)}',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primary,
                                  ),
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

/// طلبات انضمام واردة إلى مشروعك (أنت قائد فريق الطلاب).
class _IncomingOnMyProjectTab extends StatefulWidget {
  const _IncomingOnMyProjectTab();

  @override
  State<_IncomingOnMyProjectTab> createState() =>
      _IncomingOnMyProjectTabState();
}

class _IncomingOnMyProjectTabState extends State<_IncomingOnMyProjectTab> {
  Future<List<dynamic>>? _f;
  int _appliedSessionRev = -1;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final rev = context.watch<AuthProvider>().sessionRevision;
    if (rev != _appliedSessionRev) {
      _appliedSessionRev = rev;
      _reload();
    }
  }

  void _reload() {
    if (!mounted) return;
    if (!context.read<AuthProvider>().isAuthenticated) return;
    setState(() {
      _f = context.read<GradHubApi>().peerTeamIncoming();
    });
  }

  Future<void> _approve(String id) async {
    try {
      await context.read<GradHubApi>().peerOwnerApprove(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم قبول الطالب في الفريق')),
        );
        _reload();
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${e.response?.data ?? e.message}')),
        );
      }
    }
  }

  Future<void> _reject(String id) async {
    try {
      await context.read<GradHubApi>().peerOwnerReject(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم رفض الطلب')),
        );
        _reload();
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${e.response?.data ?? e.message}')),
        );
      }
    }
  }

  static String incomingLabel(String s) => switch (s) {
        'pending' => 'بانتظار قرارك',
        'accepted' => 'مقبول',
        'rejected' => 'مرفوض',
        'cancelled' => 'أُلغي',
        _ => s,
      };

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: _f,
      builder: (context, snap) {
        if (_f == null || snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Text('${snap.error}'));
        }
        final list = snap.data ?? [];
        return RefreshIndicator.adaptive(
          onRefresh: () async {
            _reload();
            final fut = _f;
            if (fut != null) await fut;
          },
          child: list.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 112),
                  children: [
                    _SectionHeader(
                      icon: Icons.move_to_inbox_rounded,
                      title: 'طلبات الزملاء لمشروعك',
                      subtitle:
                          'يظهر هنا ما يخص مشروع قائد الفريق الطلّابي. طلبات «مشاريع الدكتور» تُدار من حساب الأستاذ وليس من هذا الجدول.',
                    ),
                    const _EmptyHint(
                      message:
                          'لا طلبات واردة حالياً. تأكّد أن قبول الانضمام مفتوح من إعدادات الفريق.',
                    ),
                  ],
                )
              : ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 112),
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final m = _dynMap(list[i]);
                    final id = m['_id']?.toString() ?? '';
                    final st = m['status']?.toString() ?? '';
                    final req = _dynMap(m['requester']);
                    final proj = _dynMap(m['project']);
                    final pending = st == 'pending';
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              proj['title']?.toString() ?? '—',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              '${req['name'] ?? ''} · ${req['uniNumber'] ?? ''}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'الحالة: ${incomingLabel(st)}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            if (pending && id.isNotEmpty) ...[
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () => _reject(id),
                                      child: const Text('رفض'),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: FilledButton(
                                      onPressed: () => _approve(id),
                                      child: const Text('قبول'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
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

class _MySupervisorTab extends StatefulWidget {
  const _MySupervisorTab();

  @override
  State<_MySupervisorTab> createState() => _MySupervisorTabState();
}

class _MySupervisorTabState extends State<_MySupervisorTab> {
  Future<Map<String, dynamic>>? _memo;
  String? _loadedPid;

  void _loadProject(String pid) {
    final api = context.read<GradHubApi>();
    setState(() {
      _loadedPid = pid;
      _memo = api.getProject(pid);
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final pid = context.read<AuthProvider>().studentProjectId;
      if (!mounted || pid == null || pid.isEmpty) {
        return;
      }
      _loadProject(pid);
    });
  }

  static List<Map<String, dynamic>> _doctorList(Map<String, dynamic> data) {
    final out = <Map<String, dynamic>>[];
    void add(dynamic raw) {
      if (raw is! Map) return;
      final m = Map<String, dynamic>.from(raw);
      final has =
          (m['name']?.toString().isNotEmpty == true) ||
              (m['email']?.toString().isNotEmpty == true);
      if (!has) return;
      if (out.any((e) => e['name'] == m['name'] && e['email'] == m['email'])) {
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

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final pid = auth.studentProjectId;

    if (!auth.studentHasProject || pid == null || pid.isEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(24, 32, 24, 112),
        children: [
          Icon(Icons.person_search_rounded,
              size: 48, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 16),
          Text(
            'لا يوجد مشروع مسجَّل لحسابك بعد',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          Text(
            'بعد إنشاء مشروع أو قبولك في فريق، يظهر هنا اسم المشرف الأكاديمي إن وُجد.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.45,
                ),
          ),
        ],
      );
    }

    if (_loadedPid != pid) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _loadProject(pid);
        }
      });
    }

    return RefreshIndicator.adaptive(
      onRefresh: () async {
        final api = context.read<GradHubApi>();
        final refreshPid = auth.studentProjectId!;
        final fut = api.getProject(refreshPid);
        setState(() {
          _memo = fut;
        });
        await fut;
      },
      child: FutureBuilder<Map<String, dynamic>>(
        future: _memo,
        builder: (context, snap) {
          if (_memo == null || snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError || snap.data == null) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              children: [
                Text(
                  '${snap.error}',
                  textAlign: TextAlign.center,
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                const SizedBox(height: 16),
                Center(
                  child: FilledButton.tonal(
                    onPressed: () {
                      final api = context.read<GradHubApi>();
                      final retryPid = auth.studentProjectId!;
                      setState(() {
                        _memo = api.getProject(retryPid);
                      });
                    },
                    child: const Text('إعادة المحاولة'),
                  ),
                ),
              ],
            );
          }

          final data = snap.data!;
          final doctors = _doctorList(data);
          final short = projectSupervisorsShortLabel(data);
          final team = data['teamStudents'];
          final nTeam = team is List ? team.length : 0;
          final title = data['title']?.toString() ?? '';

          final theme = Theme.of(context);

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 112),
            children: [
              Text(
                'مشروعي الحالي',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              if (title.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    title,
                    style: theme.textTheme.titleSmall,
                  ),
                ),
              const SizedBox(height: 18),
              _SectionHeader(
                icon: Icons.co_present_rounded,
                title: 'المشرف الأكاديمي',
                subtitle:
                    short == '—'
                        ? 'لم يُعيَّن بعد مشرف رسمي. إذا كنت قائد فريق بدون مشرف، أرسل دعوات من «للدكاترة».'
                        : 'المشرفون المرتبطون بمشروعك في النظام.',
              ),
              if (doctors.isEmpty)
                _EmptyHint(
                  message: short == '—'
                      ? 'لا يظهر اسم مشرف في السجل. يمكن أن يظهر لاحقاً بعد قبول أحد الأساتذة لدعوتك.'
                      : 'اسم المشرف (نص فقط): $short',
                )
              else
                ...doctors.map(
                  (d) => Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      title: Text(
                        d['name']?.toString() ?? 'مشرف',
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      subtitle: (d['email'] != null &&
                              d['email'].toString().isNotEmpty &&
                              !d['email'].toString().endsWith('@seed.local'))
                          ? Text(d['email'].toString())
                          : null,
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.groups_outlined),
                  title: const Text('حجم الفريق المسجَّل'),
                  subtitle: Text(
                    nTeam == 0
                        ? 'لا بيانات أعضاء في الاستجابة — افتح تفاصيل المشروع للقائمة الكاملة.'
                        : '$nTeam طالب مسجَّل على المشروع',
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
