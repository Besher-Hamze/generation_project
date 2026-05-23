import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';

import '../../core/widgets/app_logo.dart';
import '../../data/grad_hub_api.dart';

enum _AssistTab { chat, projectSearch }

const _searchQuickPrompts = <String>[
  'مشاريع عن التعلم الآلي أو الذكاء الاصطناعي',
  'مشاريع غير منجزة',
  'مشاريع عن الشبكات أو الأمن السيبراني',
];

class _ChatMessage {
  const _ChatMessage({required this.isUser, required this.text});
  final bool isUser;
  final String text;
}

class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key});

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  final _q = TextEditingController();
  final _scroll = ScrollController();
  _AssistTab _tab = _AssistTab.chat;
  final List<_ChatMessage> _messagesChat = [];
  final List<_ChatMessage> _messagesSearch = [];
  String _histChat = '';
  String _histSearch = '';
  bool _busy = false;
  String? _err;
  List<String> _models = const ['qwen2.5:7b'];
  String _selectedModel = 'qwen2.5:7b';
  bool _modelsLoading = true;

  List<_ChatMessage> get _activeMessages =>
      _tab == _AssistTab.chat ? _messagesChat : _messagesSearch;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadModels());
  }

  Future<void> _loadModels() async {
    try {
      final list = await context.read<GradHubApi>().aiChatModels();
      if (!mounted) {
        return;
      }
      setState(() {
        _models = list.isEmpty ? const ['qwen2.5:7b'] : list;
        if (!_models.contains(_selectedModel)) {
          _selectedModel = _models.first;
        }
        _modelsLoading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _modelsLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _q.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) {
        return;
      }
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    });
  }

  void _clearChat() {
    setState(() {
      if (_tab == _AssistTab.chat) {
        _messagesChat.clear();
        _histChat = '';
      } else {
        _messagesSearch.clear();
        _histSearch = '';
      }
      _err = null;
    });
  }

  Future<void> _send() async {
    final txt = _q.text.trim();
    if (txt.isEmpty || _busy) {
      return;
    }
    setState(() {
      _busy = true;
      _err = null;
      _activeMessages.add(_ChatMessage(isUser: true, text: txt));
    });
    _q.clear();
    _scrollToEnd();

    try {
      if (_tab == _AssistTab.chat) {
        await _sendChat(txt);
      } else {
        await _sendProjectSearch(txt);
      }
    } on DioException catch (e) {
      if (mounted) {
        setState(() {
          _err = e.response?.data?.toString() ?? e.message ?? 'خطأ بالشبكة';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _err = e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
      _scrollToEnd();
    }
  }

  Future<void> _sendChat(String txt) async {
    final resp = await context.read<GradHubApi>().aiChat(
          query: txt,
          conversationHistory: _histChat,
          model: _selectedModel,
        );
    final answer = resp['message'] ??
        resp['answer'] ??
        resp['response'] ??
        resp['text'] ??
        resp.toString();
    final answerStr = answer.toString();
    if (!mounted) {
      return;
    }
    setState(() {
      _histChat = '${_histChat}Q: $txt\nA: $answerStr\n';
      _messagesChat.add(_ChatMessage(isUser: false, text: answerStr));
    });
    _scrollToEnd();
  }

  Future<void> _sendProjectSearch(String userQuery) async {
    final resp =
        await context.read<GradHubApi>().aiVectorSearch(query: userQuery);
    final answerStr = _formatVectorSearchMarkdown(resp);
    if (!mounted) {
      return;
    }
    setState(() {
      _histSearch = '${_histSearch}Q: $userQuery\nA: $answerStr\n';
      _messagesSearch.add(_ChatMessage(isUser: false, text: answerStr));
    });
    _scrollToEnd();
  }

  /// يعرّض بدون ترتيب إضافي: نفس ترتيب ‎`/api/search`‎ من الخادوم.
  String _formatVectorSearchMarkdown(Map<String, dynamic> resp) {
    final q = resp['query']?.toString() ?? '';
    final resultsRaw = resp['results'];
    if (resultsRaw is! List || resultsRaw.isEmpty) {
      return 'لم يُعثر على نتائج قريبة للاستعلام: «${q.trim()}».';
    }
    final lines = <String>[
      '**الاستعلام:** ${q.trim().isEmpty ? '—' : q.trim()}',
      '',
      '**عدد النتائج:** ${resp['count'] ?? resultsRaw.length}',
      '',
    ];
    var i = 1;
    for (final raw in resultsRaw) {
      lines.add('### $i');
      if (raw is Map) {
        final m = Map<String, dynamic>.from(raw);
        String? text;
        for (final key in [
          'page_content',
          'pageContent',
          'content',
          'text',
          'snippet'
        ]) {
          final t = m[key]?.toString().trim();
          if (t != null && t.isNotEmpty) {
            text = t;
            break;
          }
        }
        if (text != null) {
          lines.add(text);
        } else {
          lines.add(_mapToReadableLines(m));
        }
      } else {
        lines.add(raw.toString());
      }
      lines.add('');
      i++;
    }
    return lines.join('\n').trimRight();
  }

  String _mapToReadableLines(Map<String, dynamic> m) {
    final skip = {'page_content', 'pageContent'};
    final parts = <String>[];
    m.forEach((k, v) {
      if (skip.contains(k) || v == null) return;
      final s = v.toString().trim();
      if (s.isEmpty || s == '{}') return;
      parts.add('**$k:** $s');
    });
    return parts.isEmpty ? '$m'.trim() : parts.join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppLogo(size: 30, circular: true),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                'المساعد',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        actions: [
          if (_tab == _AssistTab.chat)
            _modelsLoading
                ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : PopupMenuButton<String>(
                    tooltip: 'النموذج',
                    enabled: !_busy && _models.isNotEmpty,
                    onSelected: (v) => setState(() => _selectedModel = v),
                    itemBuilder: (ctx) => [
                      for (final m in _models)
                        CheckedPopupMenuItem<String>(
                          value: m,
                          checked: m == _selectedModel,
                          child: Text(m, overflow: TextOverflow.ellipsis),
                        ),
                    ],
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Icon(
                        Icons.memory_rounded,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
          if (_activeMessages.isNotEmpty)
            IconButton(
              tooltip: 'مسح المحادثة',
              onPressed: _busy ? null : _clearChat,
              icon: const Icon(Icons.delete_outline_rounded),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            child: SegmentedButton<_AssistTab>(
              segments: [
                const ButtonSegment<_AssistTab>(
                  value: _AssistTab.chat,
                  label: Text('دردشة'),
                  icon: Icon(Icons.chat_bubble_outline_rounded),
                ),
                const ButtonSegment<_AssistTab>(
                  value: _AssistTab.projectSearch,
                  label: Text('بحث مشاريع'),
                  icon: Icon(Icons.manage_search_rounded),
                ),
              ],
              selected: {_tab},
              emptySelectionAllowed: false,
              showSelectedIcon: false,
              onSelectionChanged: (s) {
                setState(() {
                  _tab = s.first;
                  _err = null;
                });
              },
            ),
          ),
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    scheme.primaryContainer.withValues(alpha: 0.22),
                    scheme.surface,
                  ],
                ),
              ),
              child: _activeMessages.isEmpty && _err == null
                  ? _EmptyAssistantView(
                      tab: _tab,
                      onPick: (s) {
                        _q.text = s;
                        _send();
                      },
                    )
                  : ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                      itemCount: _activeMessages.length + (_busy ? 1 : 0) + (_err != null ? 1 : 0),
                      itemBuilder: (context, i) {
                        var idx = i;
                        if (_err != null) {
                          if (idx == 0) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Material(
                                color: scheme.errorContainer.withValues(alpha: 0.45),
                                borderRadius: BorderRadius.circular(14),
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Icon(Icons.error_outline_rounded,
                                          color: scheme.error, size: 22),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          _err!,
                                          style: theme.textTheme.bodyMedium?.copyWith(
                                            color: scheme.onErrorContainer,
                                            height: 1.4,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        visualDensity: VisualDensity.compact,
                                        onPressed: () => setState(() => _err = null),
                                        icon: const Icon(Icons.close_rounded),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }
                          idx -= 1;
                        }
                        if (_busy && idx == _activeMessages.length) {
                          return Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _TypingBubble(
                                colorScheme: scheme,
                                label: _tab == _AssistTab.projectSearch
                                    ? 'جاري البحث في فهرس المشاريع…'
                                    : 'جاري التفكير… (قد يصل الانتظار إلى عدة دقائق)',
                              ),
                            ),
                          );
                        }
                        if (idx >= _activeMessages.length) {
                          return const SizedBox.shrink();
                        }
                        final m = _activeMessages[idx];
                        return _MessageBubble(message: m, scheme: scheme);
                      },
                    ),
            ),
          ),
          if (_tab == _AssistTab.projectSearch &&
              (_activeMessages.isNotEmpty || _err != null))
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Align(
                alignment: Alignment.centerRight,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: _searchQuickPrompts
                      .map(
                        (s) => ActionChip(
                          label: Text(s, style: theme.textTheme.bodySmall),
                          onPressed: _busy
                              ? null
                              : () {
                                  _q.text = s;
                                  _send();
                                },
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          Material(
            elevation: 10,
            shadowColor: Colors.black.withValues(alpha: 0.08),
            color: scheme.surface,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(12, 10, 12, bottomInset + 16 + 56),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _q,
                        minLines: 1,
                        maxLines: 5,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _send(),
                        decoration: InputDecoration(
                          hintText: _tab == _AssistTab.chat
                              ? 'اكتب سؤالك عن المشروع أو الإجراءات…'
                              : 'اكتب كلمات بحث أو وصف الموضوع (مثل: أمن معلومات، تعلّم عميق…)…',
                          filled: true,
                          fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide(
                              color: scheme.outlineVariant.withValues(alpha: 0.5),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide(color: scheme.primary, width: 1.6),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                        shape: const CircleBorder(),
                      ),
                      onPressed: _busy ? null : _send,
                      child: _busy
                          ? SizedBox.square(
                              dimension: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: scheme.onPrimary,
                              ),
                            )
                          : Icon(Icons.send_rounded, color: scheme.onPrimary),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyAssistantView extends StatelessWidget {
  const _EmptyAssistantView({required this.tab, required this.onPick});

  final _AssistTab tab;
  final void Function(String) onPick;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isSearch = tab == _AssistTab.projectSearch;
    final title = isSearch
        ? 'بحث شبيه بالمشاريع (فهرس متجه)'
        : 'مرحباً — كيف أقدر أساعدك؟';
    final blurb = isSearch
        ? 'يُرسَل استعلامك إلى خدمة الفهرسة على الخادوم (بدون تصنيف أو تلخيص إضافي في التطبيق). النتائج بنفس الترتيب والدرجة التي تُعيدها نقطة البحث.'
        : 'الإجابات تُولَّد عبر الخادوم وقد تحتاج مراجعة أكاديمية. اكتب سؤالك في الحقل أسفل الشاشة.';
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      children: [
        Center(
          child: Column(
            children: [
              const AppLogo(size: 72, circular: true),
              const SizedBox(height: 18),
              Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                blurb,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        if (isSearch) ...[
          const SizedBox(height: 28),
          Text(
            'أمثلة بحث سريعة',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          ..._searchQuickPrompts.map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                elevation: 0,
                shadowColor: Colors.transparent,
                child: InkWell(
                  onTap: () => onPick(s),
                  borderRadius: BorderRadius.circular(16),
                  child: Ink(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: scheme.primary.withValues(alpha: 0.18),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.arrow_back_ios_new_rounded,
                            size: 16, color: scheme.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            s,
                            style:
                                theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.scheme});

  final _ChatMessage message;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = message.isUser;

    Widget core;
    if (isUser) {
      core = Text(
        message.text,
        style: theme.textTheme.bodyMedium?.copyWith(
          height: 1.45,
          color: scheme.onPrimaryContainer,
        ),
      );
    } else {
      core = MarkdownBody(
        selectable: true,
        data: message.text,
        styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
          p: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
        ),
      );
    }

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.88,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: isUser
                  ? scheme.primaryContainer
                  : scheme.surfaceContainerHighest.withValues(alpha: 0.55),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(isUser ? 18 : 4),
                bottomRight: Radius.circular(isUser ? 4 : 18),
              ),
              border: Border.all(
                color: isUser
                    ? scheme.primary.withValues(alpha: 0.12)
                    : scheme.outlineVariant.withValues(alpha: 0.4),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isUser) ...[
                    Icon(Icons.smart_toy_outlined, size: 20, color: scheme.primary),
                    const SizedBox(width: 10),
                  ],
                  Expanded(child: core),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TypingBubble extends StatefulWidget {
  const _TypingBubble({
    required this.colorScheme,
    required this.label,
  });

  final ColorScheme colorScheme;
  final String label;

  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = widget.colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.45)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.smart_toy_outlined, size: 20, color: scheme.primary),
            const SizedBox(width: 10),
            AnimatedBuilder(
              animation: _c,
              builder: (context, _) {
                final o = 0.35 + 0.65 * (0.5 + 0.5 * (1 - (_c.value * 2 - 1).abs()));
                return Text(
                  widget.label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant.withValues(alpha: o),
                        fontWeight: FontWeight.w600,
                      ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
