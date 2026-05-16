import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/grad_hub_api.dart';

/// إنشاء لجنة باسم واختيار عدة دكاترة وتحديد رئيس للجنة (يعرض للطلاب مع اسم اللجنة).
class AdminCreateCommitteeScreen extends StatefulWidget {
  const AdminCreateCommitteeScreen({super.key});

  @override
  State<AdminCreateCommitteeScreen> createState() =>
      _AdminCreateCommitteeScreenState();
}

class _AdminCreateCommitteeScreenState extends State<AdminCreateCommitteeScreen> {
  final _label = TextEditingController();
  Future<List<Map<String, dynamic>>>? _doctorsFuture;
  final Set<String> _selectedIds = {};
  String? _presidentId;
  bool _busy = false;
  String? _err;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      setState(() {
        _doctorsFuture = context.read<GradHubApi>().getList('/doctors').then(
          (raw) {
            final list = raw
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList();
            list.sort((a, b) {
              final na = '${a['name'] ?? a['email'] ?? ''}';
              final nb = '${b['name'] ?? b['email'] ?? ''}';
              return na.compareTo(nb);
            });
            return list;
          },
        );
      });
    });
  }

  @override
  void dispose() {
    _label.dispose();
    super.dispose();
  }

  void _toggleDoctor(String id, bool selected) {
    setState(() {
      if (selected) {
        _selectedIds.add(id);
        _presidentId ??= id;
      } else {
        _selectedIds.remove(id);
        if (_presidentId == id) {
          _presidentId =
              _selectedIds.isNotEmpty ? _selectedIds.first : null;
        }
      }
    });
  }

  Future<void> _submit() async {
    final label = _label.text.trim();
    if (label.isEmpty) {
      setState(() => _err = 'أدخل اسماً للجنة (مثلاً: لجنة A).');
      return;
    }
    if (_selectedIds.isEmpty) {
      setState(() => _err = 'اختر دكتوراً واحداً على الأقل.');
      return;
    }
    var pres = _presidentId;
    if (pres == null || !_selectedIds.contains(pres)) {
      pres = _selectedIds.first;
    }

    final api = context.read<GradHubApi>();
    final messenger = ScaffoldMessenger.of(context);
    setState(() {
      _busy = true;
      _err = null;
    });

    try {
      final created = await api.adminCreateCommittee(
        label: label,
        presidentDoctorId: pres,
      );
      final cid = created['_id']?.toString() ?? '';
      if (cid.isEmpty) {
        throw StateError('لم يُرجع الخادم معرف اللجنة.');
      }
      for (final did in _selectedIds) {
        await api.adminLinkDoctorToCommittee(
          committeeId: cid,
          doctorId: did,
          isPresident: did == pres,
        );
      }
      await api.adminPatchCommitteePresident(
        committeeId: cid,
        presidentDoctorId: pres,
      );
      if (!mounted) {
        return;
      }
      messenger.showSnackBar(const SnackBar(content: Text('تم إنشاء اللجنة وربط الأعضاء.')));
      Navigator.of(context).pop(true);
    } on DioException catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _busy = false;
        _err = '${e.response?.data ?? e.message}';
      });
    } on StateError catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _busy = false;
        _err = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(title: const Text('لجنة جديدة')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _doctorsFuture,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('${snap.error}'));
          }
          final doctors = snap.data ?? [];

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
            children: [
              TextField(
                controller: _label,
                enabled: !_busy,
                decoration: const InputDecoration(
                  labelText: 'اسم اللجنة',
                  hintText: 'مثال: لجنة A',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'يظهر اسم اللجنة للطلاب في صفحة المشروع بعد توزيع المشروع على اللجنة.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'أعضاء اللجنة',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              if (doctors.isEmpty)
                const Text('لا دكاترة في النظام.')
              else
                ...doctors.map((d) {
                  final id = d['_id']?.toString() ?? '';
                  if (id.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  final name =
                      (d['name']?.toString().trim().isNotEmpty == true)
                          ? d['name'].toString()
                          : (d['email']?.toString() ?? id);
                  final sel = _selectedIds.contains(id);
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: CheckboxListTile(
                      value: sel,
                      onChanged: _busy
                          ? null
                          : (v) => _toggleDoctor(id, v ?? false),
                      title: Text(name),
                      subtitle: (d['email'] != null &&
                              d['email'].toString().isNotEmpty)
                          ? Text(
                              d['email'].toString(),
                              style: theme.textTheme.bodySmall,
                            )
                          : null,
                      secondary: sel
                          ? Radio<String>(
                              value: id,
                              groupValue: _presidentId,
                              onChanged: _busy
                                  ? null
                                  : (v) =>
                                      setState(() => _presidentId = v),
                            )
                          : null,
                    ),
                  );
                }),
              if (_err != null) ...[
                const SizedBox(height: 12),
                Text(
                  _err!,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _busy ? null : _submit,
                icon: _busy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.groups_3_rounded),
                label: Text(_busy ? 'جاري الحفظ…' : 'حفظ اللجنة'),
              ),
            ],
          );
        },
      ),
    );
  }
}
