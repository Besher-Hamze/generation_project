import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../assistant/assistant_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../join/doctor_review_hub_screen.dart';
import '../join/student_join_screen.dart';
import '../management/admin_current_year_projects_screen.dart';
import '../management/admin_hub_screen.dart';
import '../projects/projects_discover_screen.dart';
import '../sessions/doctor_supervised_active_projects_screen.dart';
import '../sessions/sessions_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final role = context.watch<AuthProvider>().role ?? 'student';

    late final List<Widget> pages;
    late final List<NavigationDestination> dest;

    switch (role) {
      case 'admin':
        pages = [
          DashboardScreen(role: role),
          const AssistantScreen(),
          const AdminHubScreen(),
          const AdminCurrentYearProjectsScreen(),
          const SessionsScreen(showCreateHint: false),
        ];
        dest = const [
          NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: 'اللوحة'),
          NavigationDestination(
              icon: Icon(Icons.smart_toy_outlined),
              selectedIcon: Icon(Icons.smart_toy_rounded),
              label: 'مساعِد'),
          NavigationDestination(
              icon: Icon(Icons.manage_accounts_outlined),
              selectedIcon: Icon(Icons.manage_accounts),
              label: 'البيانات'),
          NavigationDestination(
              icon: Icon(Icons.library_books_outlined),
              selectedIcon: Icon(Icons.library_books),
              label: 'مشاريع'),
          NavigationDestination(
              icon: Icon(Icons.event_note_outlined),
              selectedIcon: Icon(Icons.event_note),
              label: 'جلسات'),
        ];
      case 'doctor':
        pages = [
          DashboardScreen(role: role),
          const AssistantScreen(),
          const DoctorReviewHubScreen(),
          const DoctorSupervisedActiveProjectsScreen(),
          const ProjectsDiscoverScreen(),
          const SessionsScreen(showCreateHint: true),
        ];
        dest = const [
          NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: 'اللوحة'),
          NavigationDestination(
              icon: Icon(Icons.smart_toy_outlined),
              selectedIcon: Icon(Icons.smart_toy_rounded),
              label: 'مساعِد'),
          NavigationDestination(
              icon: Icon(Icons.fact_check_outlined),
              selectedIcon: Icon(Icons.fact_check),
              label: 'المراجعة'),
          NavigationDestination(
              icon: Icon(Icons.how_to_reg_outlined),
              selectedIcon: Icon(Icons.how_to_reg_rounded),
              label: 'إشرافي'),
          NavigationDestination(
              icon: Icon(Icons.library_books_outlined),
              selectedIcon: Icon(Icons.library_books),
              label: 'مشاريع'),
          NavigationDestination(
              icon: Icon(Icons.event_note_outlined),
              selectedIcon: Icon(Icons.event_note),
              label: 'جلسات'),
        ];
      default:
        pages = [
          DashboardScreen(role: role),
          const AssistantScreen(),
          const ProjectsDiscoverScreen(),
          const StudentJoinScreen(),
          const SessionsScreen(showCreateHint: false),
        ];
        dest = const [
          NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: 'اللوحة'),
          NavigationDestination(
              icon: Icon(Icons.smart_toy_outlined),
              selectedIcon: Icon(Icons.smart_toy_rounded),
              label: 'مساعِد'),
          NavigationDestination(
              icon: Icon(Icons.explore_outlined),
              selectedIcon: Icon(Icons.explore),
              label: 'اكتشف'),
          NavigationDestination(
              icon: Icon(Icons.mail_outline),
              selectedIcon: Icon(Icons.mail),
              label: 'انضمام'),
          NavigationDestination(
              icon: Icon(Icons.event_note_outlined),
              selectedIcon: Icon(Icons.event_note),
              label: 'جلسات'),
        ];
    }

    final maxIdx = pages.length - 1;
    final safeIdx = _index.clamp(0, maxIdx);

    return DecoratedBox(
      decoration: AppTheme.meshBackground(context),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: IndexedStack(
          index: safeIdx,
          children: pages,
        ),
        bottomNavigationBar: NavigationBar(
          height: 72,
          elevation: 0,
          destinations: dest,
          selectedIndex: safeIdx,
          onDestinationSelected: (i) => setState(() => _index = i),
        ),
      ),
    );
  }
}
