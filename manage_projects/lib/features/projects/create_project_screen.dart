import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/academic_year.dart';
import '../../data/grad_hub_api.dart';
import '../../providers/auth_provider.dart';

class CreateProjectScreen extends StatefulWidget {
  const CreateProjectScreen({super.key});

  @override
  State<CreateProjectScreen> createState() => _CreateProjectScreenState();
}

class _CreateProjectScreenState extends State<CreateProjectScreen> {
  final _title = TextEditingController();
  final _desc = TextEditingController();
  final _year = TextEditingController();
  bool _busy = false;
  String? _err;

  @override
  void initState() {
    super.initState();
    _year.text = activeAcademicYearLabelForNow();
  }

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    _year.dispose();
    super.dispose();
  }

  Future<void> _pickAcademicYear() async {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final selected = calendarAnchorForAcademicYearField(_year.text);
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('العام الدراسي (صيغة: 2025-2026 بحسب اليوم)'),
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
      setState(() => _err = 'املأ كل الحقول؛ العام يُعرَض بالشكل 2025-2026 وفق اليوم؛ غيّره من المنتقي عند اللزوم.');
      return;
    }
    setState(() {
      _busy = true;
      _err = null;
    });
    try {
      await context.read<GradHubApi>().createStudentProject({
        'title': t,
        'description': d,
        'academicYear': y,
      });
      if (!mounted) {
        return;
      }
      await context.read<AuthProvider>().refreshMe();
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } on DioException catch (e) {
      setState(() => _err = e.response?.data?.toString() ?? e.message);
    } catch (e) {
      setState(() => _err = e.toString());
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('مشروع جديد')),
      body: SingleChildScrollView(
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
            Text(
                  'إنشاء مشروع تخرّج',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'يُنشأ المشروع ويُعرَف كمشروعك الحالي (حسب قواعد الخادوم).',
              style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 22),
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
                    suffixIcon:
                        Icon(Icons.calendar_month_rounded, color: theme.colorScheme.primary),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: _busy ? null : _submit,
              icon: _busy
                  ? SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                    )
                  : const Icon(Icons.publish_rounded),
              label: Text(_busy ? 'جاري الإرسال…' : 'إنشاء'),
            ),
          ],
        ),
      ),
    );
  }
}
