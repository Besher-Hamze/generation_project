import 'package:flutter/material.dart';

/// شعار التطبيق: طبقة لون ثنائية مع أيقونة أكاديمية (بدون ملف صورة خارجي).
class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.size = 56,
    this.circular = false,
  });

  final double size;
  /// إن كان true يُستخدم دائرة كاملة (مثلاً لفقاعات الدردشة).
  final bool circular;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = circular ? size / 2 : size * 0.24;
    return Semantics(
      label: 'شعار مرشد المشاريع',
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: circular ? BoxShape.circle : BoxShape.rectangle,
          borderRadius: circular ? null : BorderRadius.circular(radius),
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              scheme.primary,
              Color.lerp(scheme.primary, scheme.tertiary, 0.55)!,
            ],
          ),
          boxShadow: [
            BoxShadow(
              blurRadius: size * 0.08,
              offset: Offset(0, size * 0.04),
              color: scheme.primary.withValues(alpha: 0.28),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Icon(
          Icons.menu_book_rounded,
          color: Colors.white.withValues(alpha: 0.95),
          size: size * 0.46,
          shadows: const [
            Shadow(
              blurRadius: 6,
              color: Colors.black26,
              offset: Offset(0, 1),
            ),
          ],
        ),
      ),
    );
  }
}
