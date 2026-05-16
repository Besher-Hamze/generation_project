import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/utils/hide_technical_fields.dart';
import '../../data/grad_hub_api.dart';

class ApiListScreen extends StatelessWidget {
  const ApiListScreen({super.key, required this.title, required this.apiPath});

  final String title;
  final String apiPath;

  @override
  Widget build(BuildContext context) {
    final api = context.read<GradHubApi>();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(title: Text(title)),
      body: FutureBuilder<List<dynamic>>(
        future: api.getList(apiPath),
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: SelectableText('${snap.error}'),
              ),
            );
          }
          final list = snap.data ?? [];
          if (list.isEmpty) {
            return const Center(child: Text('قائمة فارغة'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(14),
            itemCount: list.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final m = Map<String, dynamic>.from(list[i] as Map);

              final titleLine = [
                m['name'],
                m['title'],
                m['uniNumber'],
                m['email'],
              ]
                  .map((e) => e?.toString() ?? '')
                  .firstWhere((s) => s.isNotEmpty, orElse: () => '');

              final subtitle = summarizePublicRecord(m, maxParts: 4);

              return Card(
                child: ListTile(
                  title: Text(titleLine.isEmpty ? 'سجل إداري' : titleLine),
                  subtitle: Text(
                    subtitle,
                    maxLines: 5,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () {
                    final pairs = <MapEntry<String, String>>[];
                    collectPublicFields(m, pairs);
                    showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      showDragHandle: true,
                      builder: (ctx) {
                        final maxH =
                            MediaQuery.sizeOf(context).height * 0.65;
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                          child: pairs.isEmpty
                              ? Center(
                                  child: Text(
                                    'لا حقول عامة لهذا السجل بعد إخفاء المعرفات.',
                                    style: theme.textTheme.bodyLarge,
                                  ),
                                )
                              : ConstrainedBox(
                                  constraints: BoxConstraints(maxHeight: maxH),
                                  child: ListView.separated(
                                    shrinkWrap: true,
                                    itemCount: pairs.length,
                                    separatorBuilder: (_, __) =>
                                        const Divider(height: 1),
                                    itemBuilder: (context, idx) {
                                      final e = pairs[idx];
                                      return ListTile(
                                        title: Text(
                                          e.key,
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                            color: theme.colorScheme.secondary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        subtitle: SelectableText(
                                          e.value,
                                          style: theme.textTheme.bodyLarge,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                        );
                      },
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
