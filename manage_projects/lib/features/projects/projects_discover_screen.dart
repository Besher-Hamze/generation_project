import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/academic_year.dart';
import '../../core/utils/project_supervisor_label.dart';
import '../../data/grad_hub_api.dart';
import '../../providers/auth_provider.dart';
import 'create_project_screen.dart';
import 'project_detail_screen.dart';

List<String> _sortedUniqueYearsFromProjects(List<dynamic> list) {
  final set = <String>{};
  for (final raw in list) {
    if (raw is! Map) {
      continue;
    }
    final m = Map<String, dynamic>.from(raw);
    final y = m['academicYear']?.toString().trim() ?? '';
    if (y.isNotEmpty && y != 'null') {
      set.add(y);
    }
  }
  final sorted = set.toList()..sort(_compareYearsDesc);
  return sorted;
}

int _compareYearsDesc(String a, String b) {
  return academicYearStartDigits(b).compareTo(academicYearStartDigits(a));
}

/// year فارغ ⇒ لا يطبّق فلتر
List<Map<String, dynamic>> _projectMapsFilteredByYear(
  List<Map<String, dynamic>> list,
  String? year,
) {
  if (year == null || year.isEmpty) {
    return List<Map<String, dynamic>>.from(list);
  }
  return list
      .where((m) => _yearsMatchSemantically(
            m['academicYear']?.toString() ?? '',
            year,
          ))
      .map((m) => Map<String, dynamic>.from(m))
      .toList();
}

/// يطابق `2025/2026` مع `2025-2026` ويعتمد سنة البداية.
bool _yearsMatchSemantically(String raw, String filterYear) {
  final a = academicYearStartDigits(raw);
  final b = academicYearStartDigits(filterYear);
  if (a >= 0 && b >= 0) {
    return a == b;
  }
  return raw.trim() == filterYear.trim();
}

String? _createdByStudentId(Map<String, dynamic> m) {
  final raw = m['createdByStudent'];
  if (raw == null || raw == 'null') {
    return null;
  }
  if (raw is Map && raw['_id'] != null) {
    return raw['_id'].toString();
  }
  return raw.toString();
}

bool _studentVisibleProject(Map<String, dynamic> m, Set<String> blockedIds) {
  final id = m['_id']?.toString();
  if (id != null && blockedIds.contains(id)) {
    return false;
  }
  final hasSup = m['supervisor'] != null;
  final ss = m['supervisors'];
  final hasSs = ss is List && ss.isNotEmpty;
  final peer = _createdByStudentId(m) != null;
  return hasSup || hasSs || peer;
}

bool _joinableNow(Map<String, dynamic> m) {
  final finished = m['isFinished'] == true;
  if (finished) {
    return false;
  }
  final hasSup = m['supervisor'] != null;
  final ss = m['supervisors'];
  final hasSs = ss is List && ss.isNotEmpty;
  final peer = _createdByStudentId(m) != null;
  if (!(hasSup || hasSs || peer)) {
    return false;
  }
  if (peer && m['enrollmentOpen'] == false) {
    return false;
  }
  return true;
}

bool _archiveProject(Map<String, dynamic> m) {
  return m['isFinished'] == true;
}

/// `null`: العام الحالي حسب التقويم إن وُجد؛ وإلا «الكل». `''`: صراحة «الكل».
String _discoverProjectsDropdownValue(List<String> years, String? choice) {
  if (choice != null) {
    if (choice.isEmpty) {
      return '';
    }
    return years.contains(choice) ? choice : '';
  }
  final active = activeAcademicYearLabelForNow();
  if (years.contains(active)) {
    return active;
  }
  return '';
}

String? _discoverProjectsAppliedYearFilter(List<String> years, String? choice) {
  if (choice != null) {
    if (choice.isEmpty) {
      return null;
    }
    return choice;
  }
  final active = activeAcademicYearLabelForNow();
  if (years.contains(active)) {
    return active;
  }
  return null;
}

class ProjectsDiscoverScreen extends StatefulWidget {
  const ProjectsDiscoverScreen({super.key});

  @override
  State<ProjectsDiscoverScreen> createState() => _ProjectsDiscoverScreenState();
}

class _ProjectsDiscoverScreenState extends State<ProjectsDiscoverScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  Future<List<dynamic>>? _future;

  /// `null`: العرض الافتراضي — العام الدراسي الحالي وفق اليوم إن وُجد في القائمة، وإلا «الكل».
  /// `''`: الطالب طلب صراحة «الكل».
  /// غير ذلك: عام محدَّد (`2025-2026`).
  String? _yearFilterChoice;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _reload();
    });
  }

  void _reload() {
    setState(() {
      _future = context.read<GradHubApi>().getList('/projects');
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final role = auth.role ?? 'student';
    final showCreateFab = role == 'student' && !auth.studentHasProject;
    final listBottomPadding = showCreateFab ? 148.0 : 100.0;

    Future<void> openCreateProject() async {
      final created = await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(
          builder: (_) => const CreateProjectScreen(),
        ),
      );
      if (!context.mounted) {
        return;
      }
      if (created == true) {
        await context.read<AuthProvider>().refreshMe();
        _reload();
      }
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('معرض مشاريع التخرّج'),
        actions: [
          if (role == 'student' && !auth.studentHasProject)
            IconButton(
              tooltip: 'إنشاء مشروع جديد',
              icon: const Icon(Icons.add_circle_outline_rounded),
              onPressed: openCreateProject,
            ),
        ],
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'متاح للانضمام'),
            Tab(text: 'منجز (قديم)'),
          ],
        ),
      ),
      floatingActionButton: showCreateFab
          ? FloatingActionButton.extended(
              onPressed: openCreateProject,
              icon: const Icon(Icons.add_rounded),
              label: const Text('مشروع جديد'),
            )
          : null,
      body: FutureBuilder<List<dynamic>>(
        future: _future,
        builder: (context, snap) {
          if (_future == null ||
              snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Padding(
              padding: const EdgeInsets.all(28),
              child: Center(child: Text('${snap.error}')),
            );
          }
          var list = List<dynamic>.from(snap.data ?? []);
          if (role == 'student') {
            final blocked = auth.blockedProjectIds.toSet();
            list = list
                .where((raw) =>
                    raw is Map &&
                    _studentVisibleProject(
                      Map<String, dynamic>.from(raw),
                      blocked,
                    ))
                .toList();
          }

          final years = _sortedUniqueYearsFromProjects(list);
          final dropdownValue =
              _discoverProjectsDropdownValue(years, _yearFilterChoice);
          final appliedYearFilter =
              _discoverProjectsAppliedYearFilter(years, _yearFilterChoice);

          final joinableMaps = list
              .where((raw) =>
                  raw is Map &&
                  _joinableNow(Map<String, dynamic>.from(raw)))
              .toList()
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();
          final archiveMaps = list
              .where((raw) =>
                  raw is Map &&
                  _archiveProject(Map<String, dynamic>.from(raw)))
              .toList()
              .map((e) => Map<String, dynamic>.from(e as Map))
              .toList();

          final joinable =
              _projectMapsFilteredByYear(joinableMaps, appliedYearFilter);
          final archive =
              _projectMapsFilteredByYear(archiveMaps, appliedYearFilter);

          final filterActive = appliedYearFilter != null &&
              appliedYearFilter.isNotEmpty;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Material(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Row(
                    children: [
                      Icon(Icons.filter_alt_outlined,
                          size: 22,
                          color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'العام الدراسي',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            Text(
                              'نشط الآن: ${activeAcademicYearLabelForNow()} '
                              '(يبدأ من أيلول)',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .outline,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: years.isEmpty
                            ? Text(
                                '—',
                                style: Theme.of(context).textTheme.bodyMedium,
                              )
                            : DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: dropdownValue.isEmpty ? '' : dropdownValue,
                                  isExpanded: true,
                                  items: [
                                    const DropdownMenuItem<String>(
                                      value: '',
                                      child: Text('الكل'),
                                    ),
                                    ...years.map(
                                      (y) => DropdownMenuItem<String>(
                                        value: y,
                                        child: Text(
                                          y,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                  ],
                                  onChanged: (v) {
                                    setState(() {
                                      _yearFilterChoice = v ?? '';
                                    });
                                  },
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabs,
                  children: [
                    _ProjectListPane(
                      list: joinable,
                      emptyMessage: filterActive
                          ? 'لا مشاريع في هذا العام ضمن هذا التبويب.'
                          : (role == 'student'
                              ? 'لا مشاريع مفتوحة للانضمام حالياً (أو أُغلق الفريق / اكتمل العدد).'
                              : 'لا مشاريع غير منجزة في القائمة.'),
                      onRefresh: _reload,
                      listBottomPadding: listBottomPadding,
                    ),
                    _ProjectListPane(
                      list: archive,
                      emptyMessage: filterActive
                          ? 'لا مشاريع منجزة في هذا العام.'
                          : 'لا مشاريع مُعلَّمة كمنجزة بعد.',
                      onRefresh: _reload,
                      archiveStyle: true,
                      listBottomPadding: listBottomPadding,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ProjectListPane extends StatelessWidget {
  const _ProjectListPane({
    required this.list,
    required this.emptyMessage,
    required this.onRefresh,
    required this.listBottomPadding,
    this.archiveStyle = false,
  });

  final List<dynamic> list;
  final String emptyMessage;
  final VoidCallback onRefresh;
  final double listBottomPadding;
  final bool archiveStyle;

  @override
  Widget build(BuildContext context) {
    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Text(emptyMessage, textAlign: TextAlign.center),
        ),
      );
    }
    return RefreshIndicator.adaptive(
      onRefresh: () async {
        onRefresh();
        await Future<void>.delayed(const Duration(milliseconds: 120));
      },
      child: ListView.separated(
        padding: EdgeInsets.fromLTRB(16, 8, 16, listBottomPadding),
        itemCount: list.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, i) {
          final m = Map<String, dynamic>.from(list[i] as Map);
          return _ProjectGlowCard(map: m, archiveStyle: archiveStyle);
        },
      ),
    );
  }
}

class _ProjectGlowCard extends StatelessWidget {
  const _ProjectGlowCard({required this.map, this.archiveStyle = false});

  final Map<String, dynamic> map;
  final bool archiveStyle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final light = Theme.of(context).brightness == Brightness.light;
    final id = map['_id']?.toString() ?? '';
    final finished = map['isFinished'] == true;
    final peer = _createdByStudentId(map) != null;
    final closed = peer && map['enrollmentOpen'] == false;
    final maxTm = map['maxTeamMembers'];

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: id.isEmpty
            ? null
            : () {
                Navigator.of(context).push<void>(
                  MaterialPageRoute(
                    builder: (_) => ProjectDetailScreen(projectId: id),
                  ),
                );
              },
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            color: light ? scheme.surface : null,
            border: Border.all(
              color: light
                  ? scheme.outlineVariant.withValues(alpha: 0.55)
                  : scheme.primary.withValues(alpha: 0.35),
              width: 1,
            ),
            boxShadow: light
                ? [
                    BoxShadow(
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                      color: Colors.black.withValues(alpha: 0.06),
                    ),
                  ]
                : AppTheme.softGlow(context),
            gradient: light
                ? null
                : LinearGradient(
                    colors: [
                      scheme.surfaceContainerHighest.withValues(alpha: 0.55),
                      scheme.surface.withValues(alpha: 0.08),
                    ],
                  ),
          ),
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      map['title']?.toString() ?? 'بدون عنوان',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  Icon(Icons.chevron_left_rounded, color: scheme.outline),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  if (finished || archiveStyle)
                    Chip(
                      avatar: Icon(Icons.archive_outlined, size: 18, color: scheme.tertiary),
                      label: const Text('منجز'),
                      visualDensity: VisualDensity.compact,
                    ),
                  if (peer && !finished)
                    Chip(
                      avatar: Icon(Icons.groups_2_outlined, size: 18, color: scheme.primary),
                      label: const Text('فريق طلاب'),
                      visualDensity: VisualDensity.compact,
                    ),
                  if (closed && !finished)
                    Chip(
                      avatar: Icon(Icons.lock_outline, size: 18, color: scheme.outline),
                      label: const Text('انتساب مغلق'),
                      visualDensity: VisualDensity.compact,
                    ),
                  if (peer &&
                      maxTm != null &&
                      maxTm.toString().isNotEmpty &&
                      maxTm != 'null')
                    Chip(
                      label: Text('حدّ الفريق: $maxTm'),
                      visualDensity: VisualDensity.compact,
                    ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                '${map['academicYear'] ?? ''}',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: scheme.secondary.withValues(alpha: 0.95),
                    ),
              ),
              if ((map['description'] ?? '').toString().isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  map['description']!.toString(),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
              const SizedBox(height: 10),
              Text(
                'المشرفون: ${projectSupervisorsShortLabel(map)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.secondary.withValues(alpha: 0.9),
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
