import 'package:flutter/material.dart';

import 'package:cv_apps/src/utils/app_language.dart';

/// The ID | ENG switch shown on every page. The language in use is filled.
/// [dark] is for pages with a dark background, [light] for light ones.
class AppLanguageSwitch extends StatelessWidget {
  const AppLanguageSwitch({super.key, this.dark = true, this.compact = false});

  final bool dark;

  /// Tighter spacing, for narrow headers.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final id = AppLanguage.isId(context);
    final fg = dark ? Colors.white : const Color(0xFF14161F);
    final line = dark
        ? Colors.white.withValues(alpha: 0.28)
        : const Color(0x33000000);
    final fill = dark
        ? Colors.white.withValues(alpha: 0.12)
        : Colors.white.withValues(alpha: 0.8);
    return Container(
      padding: EdgeInsets.all(compact ? 2 : 3),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Option(
            label: 'ID',
            active: id,
            fg: fg,
            compact: compact,
            onTap: () => AppLanguage.set(id: true),
          ),
          _Option(
            label: 'ENG',
            active: !id,
            fg: fg,
            compact: compact,
            onTap: () => AppLanguage.set(id: false),
          ),
        ],
      ),
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({
    required this.label,
    required this.active,
    required this.fg,
    required this.compact,
    required this.onTap,
  });

  final String label;
  final bool active;
  final Color fg;
  final bool compact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: active,
      label: label,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 6 : 9,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: active ? const Color(0xFF3B5BDB) : Colors.transparent,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: active ? Colors.white : fg,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
