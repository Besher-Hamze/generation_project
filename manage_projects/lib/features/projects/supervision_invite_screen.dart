import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/grad_hub_api.dart';
import '../../providers/auth_provider.dart';

/// اختيار عدة أساتذة وإرسال دعوات إشراف — أول من يقبل يربط المشروع ويُلغى الباقي.
class SupervisionInviteScreen extends StatefulWidget {
  const SupervisionInviteScreen({super.key, required this.projectId});

  final String projectId;

  @override
  State<SupervisionInviteScreen> createState() =>
      _SupervisionInviteScreenState();
}

class _SupervisionInviteScreenState extends State<SupervisionInviteScreen> {
  Future<List<dynamic>>? _doctors;
  final Set<String> _selectedIds = {};
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _doctors = context.read<GradHubApi>().publicDoctors();
  }

  Future<void> _submit() async {
    if (_selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('اختر أستاذاً واحداً على الأقل')),
      );
      return;
    }
    setState(() => _sending = true);
    try {
      await context.read<GradHubApi>().sendSupervisionInvites(
            projectId: widget.projectId,
            doctorIds: _selectedIds.toList(),
          );
      if (!mounted) {
        return;
      }
      await context.read<AuthProvider>().refreshMe();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم إرسال الدعوات — أول قبول يثبّت المشرف.')),
      );
      Navigator.of(context).pop(true);
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${e.response?.data ?? e.message}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('دعوة مشرف أكاديمي')),
      floatingActionButton: _sending
          ? null
          : FloatingActionButton.extended(
              onPressed: _submit,
              icon: const Icon(Icons.send_rounded),
              label: Text('إرسال (${_selectedIds.length})'),
            ),
      body: FutureBuilder<List<dynamic>>(
        future: _doctors,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('${snap.error}'));
          }
          final list = snap.data ?? [];
          if (list.isEmpty) {
            return const Center(child: Text('لا يوجد أساتذة مُعرّفون بعد.'));
          }
          return ListView.separated(
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              88 + MediaQuery.of(context).padding.bottom,
            ),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (context, i) {
              final m = Map<String, dynamic>.from(list[i] as Map);
              final id = m['_id']?.toString() ?? '';
              final name = m['name']?.toString() ?? '—';
              final email = m['email']?.toString() ?? '';
              final dept = m['department'];
              String deptLabel = '';
              if (dept is Map) {
                deptLabel =
                    dept['label']?.toString() ?? dept['name']?.toString() ?? '';
              }
              final checked = _selectedIds.contains(id);
              return Card(
                child: CheckboxListTile(
                  value: checked,
                  onChanged: id.isEmpty
                      ? null
                      : (v) {
                          setState(() {
                            if (v == true) {
                              _selectedIds.add(id);
                            } else {
                              _selectedIds.remove(id);
                            }
                          });
                        },
                  secondary: Icon(
                    Icons.person_search_rounded,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(name),
                  subtitle: Text(
                    [if (email.isNotEmpty) email, if (deptLabel.isNotEmpty) deptLabel]
                        .join(' · '),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
