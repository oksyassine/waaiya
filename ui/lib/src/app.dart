import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import 'backend.dart';
import 'home.dart';
import 'onboarding.dart';
import 'theme.dart';

/// Waaiya's screens. Arabic and right-to-left by default; the language comes from the backend, never from the
/// system, so it can be switched in the app (and the native side follows it).
class WaaiyaApp extends StatefulWidget {
  const WaaiyaApp({super.key, required this.backend});

  final WaaiyaBackend backend;

  @override
  State<WaaiyaApp> createState() => _WaaiyaAppState();
}

class _WaaiyaAppState extends State<WaaiyaApp> {
  AppState? _state;
  StreamSubscription<AppState>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = widget.backend.states.listen((s) => setState(() => _state = s));
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = _state;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (context) => AppLocalizations.of(context).appName,
      locale: Locale(state?.language ?? 'ar'),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: waaiyaTheme(Brightness.light),
      darkTheme: waaiyaTheme(Brightness.dark),
      builder: (context, child) => state == null
          ? ColoredBox(color: Theme.of(context).scaffoldBackgroundColor)
          : WaaiyaScope(backend: widget.backend, state: state, child: child!),
      home: const _Root(),
    );
  }
}

/// First launch: the man / woman question; then the main screen.
class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: (dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark).copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: Colors.transparent,
      ),
      child: WaaiyaScope.of(context).state.settings.gender.isEmpty ? const OnboardingScreen() : const HomeScreen(),
    );
  }
}

/// The backend and its latest snapshot, for every screen below the app.
class WaaiyaScope extends InheritedWidget {
  const WaaiyaScope({super.key, required this.backend, required this.state, required super.child});

  final WaaiyaBackend backend;
  final AppState state;

  static WaaiyaScope of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<WaaiyaScope>()!;

  @override
  bool updateShouldNotify(WaaiyaScope old) => state != old.state || backend != old.backend;
}

/// Runs a backend call; a failure is shown in a snackbar instead of being lost.
Future<T?> runAction<T>(BuildContext context, Future<T> Function(WaaiyaBackend b) action) async {
  final scope = WaaiyaScope.of(context);
  final messenger = ScaffoldMessenger.maybeOf(context);
  final l = AppLocalizations.of(context);
  try {
    return await action(scope.backend);
  } on BackendException catch (e) {
    messenger?.showSnackBar(SnackBar(content: Text(l.actionFailed(e.message.isEmpty ? e.code : e.message))));
    return null;
  }
}
