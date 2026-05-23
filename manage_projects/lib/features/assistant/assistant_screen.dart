import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:provider/provider.dart';

import '../../core/widgets/app_logo.dart';
import '../../data/grad_hub_api.dart';

const _assistantQuickPrompts = <String>[
  'ما الفرق بين طلب الانضمام لمشروع ودعوة أستاذ للإشراف؟',
  'كيف أعرف حالة طلباتي في التطبيق؟',
  'نصائح لصياغة عنوان ووصف مشروع تخرّج',
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
  final List<_ChatMessage> _messages = [];
  String _hist = '';
  bool _busy = false;
  String? _err;
  List<String> _models = const ['qwen2.5:7b'];
  String _selectedModel = 'qwen2.5:7b';
  bool _modelsLoading = true;

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
      _messages.clear();
      _hist = '';
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
      _messages.add(_ChatMessage(isUser: true, text: txt));
    });
    _q.clear();
    _scrollToEnd();

    try {
      final resp = await context.read<GradHubApi>().aiChat(
            query: txt,
            conversationHistory: _hist,
            model: _selectedModel,
          );
      final answer =
          resp['answer'] ?? resp['response'] ?? resp['text'] ?? resp.toString();
      final answerStr = answer.toString();
      if (!mounted) {
        return;
      }
      setState(() {
        _hist = '${_hist}Q: $txt\nA: $answerStr\n';
        _messages.add(_ChatMessage(isUser: false, text: answerStr));
      });
      _scrollToEnd();
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
          if (_modelsLoading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            PopupMenuButton<String>(
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
          if (_messages.isNotEmpty)
            IconButton(
              tooltip: 'مسح المحادثة',
              onPressed: _busy ? null : _clearChat,
              icon: const Icon(Icons.delete_outline_rounded),
            ),
        ],
      ),
      body: Column(
        children: [
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
              child: _messages.isEmpty && _err == null
                  ? _EmptyAssistantView(
                      onPick: (s) {
                        _q.text = s;
                        _send();
                      },
                    )
                  : ListView.builder(
                      controller: _scroll,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                      itemCount: _messages.length + (_busy ? 1 : 0) + (_err != null ? 1 : 0),
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
                        if (_busy && idx == _messages.length) {
                          return Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _TypingBubble(colorScheme: scheme),
                            ),
                          );
                        }
                        if (idx >= _messages.length) {
                          return const SizedBox.shrink();
                        }
                        final m = _messages[idx];
                        return _MessageBubble(message: m, scheme: scheme);
                      },
                    ),
            ),
          ),
          if (_messages.isNotEmpty || _err != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
              child: Align(
                alignment: Alignment.centerRight,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: _assistantQuickPrompts
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
                          hintText: 'اكتب سؤالك عن المشروع أو الإجراءات…',
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
  const _EmptyAssistantView({required this.onPick});

  final void Function(String) onPick;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      children: [
        Center(
          child: Column(
            children: [
              const AppLogo(size: 72, circular: true),
              const SizedBox(height: 18),
              Text(
                'مرحباً — كيف أقدر أساعدك؟',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'الإجابات تُولَّد عبر الخادوم وقد تحتاج مراجعة أكاديمية. جرّب أحد الاقتراحات أو اكتب سؤالك بالأسفل.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        Text(
          'اقتراحات سريعة',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        ..._assistantQuickPrompts.map(
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
                      Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: scheme.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          s,
                          style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
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
        padding: const EdgeInsets.only(bottom: 12),
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
  const _TypingBubble({required this.colorScheme});

  final ColorScheme colorScheme;

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
                  'جاري التفكير… (قد يصل الانتظار إلى عدة دقائق)',
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
