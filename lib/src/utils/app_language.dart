import 'package:flutter/widgets.dart';

/// The language of the whole app: English by default, Indonesian (ID) when the
/// reader picks it from the switch on any page.
///
/// Widgets read it with [isId] or [pick]. Reading it registers the widget as a
/// dependent, so the widget rebuilds in the new language when the reader
/// switches.
class AppLanguage {
  AppLanguage._();

  static final ValueNotifier<bool> notifier = ValueNotifier<bool>(false);

  /// Wraps the app. Put it above the router so every page is in the scope.
  static Widget scope({required Widget child}) =>
      _AppLanguageScope(notifier: notifier, child: child);

  /// Whether the app shows Indonesian. Call from a build method.
  static bool isId(BuildContext context) {
    context.dependOnInheritedWidgetOfExactType<_AppLanguageScope>();
    return notifier.value;
  }

  /// The text for the current language. Call from a build method.
  static String pick(BuildContext context, String en, String id) =>
      isId(context) ? id : en;

  /// Switches the whole app. [id] is true for Indonesian.
  static void set({required bool id}) => notifier.value = id;
}

class _AppLanguageScope extends InheritedNotifier<ValueNotifier<bool>> {
  const _AppLanguageScope({
    required ValueNotifier<bool> notifier,
    required super.child,
  }) : super(notifier: notifier);
}
