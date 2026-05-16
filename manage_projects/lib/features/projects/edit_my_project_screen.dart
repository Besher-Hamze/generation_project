import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/academic_year.dart';
import '../../data/grad_hub_api.dart';
import '../../providers/auth_provider.dart';

class EditMyProjectScreen extends StatefulWidget {
  const EditMyProjectScreen({super.key, required this.projectId});

  final String projectId;

  @override
  State<EditMyProjectScreen> createState() => _EditMyProjectScreenState();
}

class _EditMyProjectScreenState extends State<EditMyProjectScreen> {
  final _title = TextEditingController();
  final _desc = TextEditingController();
  final _year = TextEditingController();
  bool _loading = true;
  bool _busy = false;
  String? _err;
  String? _loadErr;

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    _year.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadErr = null;
    });
    try {
      final d = await context.read<GradHubApi>().getProject(widget.projectId);
      if (!mounted) return;
      _title.text = d['title']?.toString().trim() ?? '';
      _desc.text = d['description']?.toString().trim() ?? '';
      _year.text = d['academicYear']?.toString().trim() ?? '';
      if (_year.text.isEmpty) {
        _year.text = activeAcademicYearLabelForNow();
      }
      setState(() => _loading = false);
    } on DioException catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadErr = e.response?.data?.toString() ?? e.message;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadErr = e.toString();
        });
      }
    }
  }

  Future<void> _pickAcademicYear() async {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final selected = calendarAnchorForAcademicYearField(_year.text);
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('العام الدراسي (صيغة: 2025-2026)'),
          content: SizedBox(
            width: 340,
            height: 340,
            child: CalendarDatePicker(
              initialDate: selected,
              firstDate: DateTime(now.year - 15),
              lastDate: DateTime(now.year + 6),
              initialCalendarMode: DatePickerMode.year,
              onDateChanged: (d) =>
                  _year.text = academicYearLabelFromPickerDate(d),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('تم', style: TextStyle(color: theme.colorScheme.primary)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submit() async {
    final t = _title.text.trim();
    final d = _desc.text.trim();
    final y = _year.text.trim();
    final yOk = RegExp(r'^\d{4}-\d{4}$').hasMatch(y);
    if (t.length < 2 || d.length < 10 || !yOk) {
      setState(() => _err = 'املأ كل الحقول؛ العام بالشكل 2025-2026 عبر المنتقي.');
      return;
    }
    setState(() {
      _busy = true;
      _err = null;
    });
    try {
      await context.read<GradHubApi>().patchMyProjectContent(
            widget.projectId,
            title: t,
            description: d,
            academicYear: y,
          );
      if (!mounted) return;
      await context.read<AuthProvider>().refreshMe();
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on DioException catch (e) {
      setState(() => _err = e.response?.data?.toString() ?? e.message);
    } catch (e) {
      setState(() => _err = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('تعديل مشروعي')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_loadErr != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        _loadErr!,
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ),
                  Text(
                    'عدّل العنوان والوصف والعام قبل ربط المشروع بنهائي أو إضافة زملاء.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (_err != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        _err!,
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ),
                  TextField(
                    controller: _title,
                    decoration: const InputDecoration(labelText: 'العنوان'),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _desc,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      alignLabelWithHint: true,
                      labelText: 'الوصف الأكاديمي',
                    ),
                  ),
                  const SizedBox(height: 14),
                  InkWell(
                    onTap: _pickAcademicYear,
                    borderRadius: BorderRadius.circular(8),
                    child: IgnorePointer(
                      child: TextField(
                        controller: _year,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText:
                            "العام الدراسي (${activeAcademicYearLabelForNow()}) — اضغط للتعديل",
                          suffixIcon: Icon(Icons.calendar_month_rounded,
                              color: theme.colorScheme.primary),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  FilledButton.icon(
                    onPressed:
                        (_busy || _loadErr != null) ? null : _submit,
                    icon: _busy
                        ? SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: theme.colorScheme.onPrimary,
                            ),
                          )
                        : const Icon(Icons.save_rounded),
                    label: Text(_busy ? 'جاري الحفظ…' : 'حفظ التعديلات'),
                  ),
                ],
              ),
            ),
    );
  }
}
