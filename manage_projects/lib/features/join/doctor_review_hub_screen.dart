import 'package:flutter/material.dart';

import 'doctor_join_screen.dart';
import 'doctor_supervision_invitations_panel.dart';

/// تبويبان: طلبات الانضمام النمطية (مشروع بمشرف) + دعوات الإشراف من فرق الطلاب.
class DoctorReviewHubScreen extends StatelessWidget {
  const DoctorReviewHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('المراجعة'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'طلب انضمام'),
              Tab(text: 'دعوات إشراف'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            DoctorJoinRequestsPanel(),
            DoctorSupervisionInvitationsPanel(),
          ],
        ),
      ),
    );
  }
}
