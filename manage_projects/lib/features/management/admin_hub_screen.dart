import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/grad_hub_api.dart';
import 'admin_committee_assign_screen.dart';
import 'admin_create_committee_screen.dart';
import 'api_list_screen.dart';

class AdminHubScreen extends StatelessWidget {
  const AdminHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final api = context.read<GradHubApi>();
    final primary = [
      _HubEntry(
        'إنشاء لجنة',
        Icons.groups_3_rounded,
        null,
        const Color(0xFFC084FC),
        onTap: () {
          Navigator.of(context).push<void>(
            MaterialPageRoute<void>(
              builder: (_) => const AdminCreateCommitteeScreen(),
            ),
          );
        },
      ),
      _HubEntry(
        'توزيع على اللجان',
        Icons.hub_rounded,
        null,
        const Color(0xFFFF9494),
        onTap: () {
          Navigator.of(context).push<void>(
            MaterialPageRoute<void>(
              builder: (_) => const AdminCommitteeAssignScreen(),
            ),
          );
        },
      ),
      _HubEntry('الدكاترة', Icons.co_present_rounded, '/doctors', const Color(0xFFFFBD7A)),
      _HubEntry('الطلاب', Icons.groups_2_rounded, '/students', const Color(0xFF91D5FF)),
      _HubEntry('الأقسام', Icons.apartment_rounded, '/departments', const Color(0xFF63C6BF)),
    ];
    final advanced = [
      _HubEntry('اللجان (قائمة)', Icons.policy_rounded, '/committees', const Color(0xFFF59E0B)),
      _HubEntry('أعضاء اللجان (قائمة)', Icons.account_tree_rounded, '/committee-doctors', const Color(0xFF9FE8C5)),
      _HubEntry('أولويات التسجيل', Icons.timeline_rounded, '/registration-orders', const Color(0xFFB39DFF)),
      _HubEntry('القائمة السوداء', Icons.block_rounded, '/blacklists', const Color(0xFFA8B0BF)),
      _HubEntry('الإعدادات', Icons.tune_rounded, '/system-settings', const Color(0xFFE0E0FF)),
    ];
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('إدارة المنظومة')),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            sliver: SliverToBoxAdapter(
              child: Text(
                'المهام الأساسية',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisExtent: 120,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final e = primary[i];
                  return _HubTile(
                    entry: e,
                    onTap: () => _openEntry(context, api, e),
                  );
                },
                childCount: primary.length,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            sliver: SliverToBoxAdapter(
              child: Text(
                'إعدادات إضافية',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.outline,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 104),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisExtent: 120,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final e = advanced[i];
                  return _HubTile(
                    entry: e,
                    onTap: () => _openEntry(context, api, e),
                  );
                },
                childCount: advanced.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openEntry(BuildContext context, GradHubApi api, _HubEntry e) {
    if (e.onTap != null) {
      e.onTap!();
      return;
    }
    if (e.path == null) {
      return;
    }
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => Provider<GradHubApi>.value(
          value: api,
          child: ApiListScreen(title: e.title, apiPath: e.path!),
        ),
      ),
    );
  }
}

class _HubEntry {
  const _HubEntry(
    this.title,
    this.icon,
    this.path,
    this.accent, {
    this.onTap,
  });

  final String title;
  final IconData icon;
  final String? path;
  final Color accent;
  final VoidCallback? onTap;
}

class _HubTile extends StatelessWidget {
  const _HubTile({required this.entry, required this.onTap});

  final _HubEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: LinearGradient(
              colors: [
                Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withValues(alpha: 0.45),
                entry.accent.withValues(alpha: 0.12),
              ],
            ),
            border: Border.all(
              color: entry.accent.withValues(alpha: 0.55),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(entry.icon, color: entry.accent, size: 30),
                const SizedBox(height: 12),
                Text(
                  entry.title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
