import 'package:flutter/foundation.dart' show mapEquals;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import 'app.dart';
import 'backend.dart';

/// The icon next to the clock ([Capabilities.tray], Windows: desktop/windows/runner/tray.cpp). This side gives the
/// runner the menu in the app's language and whether the filter is on; the runner sends back what was chosen.
///
/// Stop goes through [runAction] like the power button, so the waiting period and the PIN hold it back the same way
/// (the runner shows the window first, where their dialog appears). Start needs no window.
class TrayBridge extends StatefulWidget {
  const TrayBridge({super.key, required this.child, this.channel = const MethodChannel('waaiya/tray')});

  final Widget child;
  final MethodChannel channel;

  @override
  State<TrayBridge> createState() => _TrayBridgeState();
}

class _TrayBridgeState extends State<TrayBridge> {
  Map<String, Object?>? _sent;

  @override
  void initState() {
    super.initState();
    widget.channel.setMethodCallHandler(_onCall);
  }

  @override
  void dispose() {
    widget.channel.setMethodCallHandler(null);
    super.dispose();
  }

  Future<Object?> _onCall(MethodCall call) async {
    if (call.method != 'action' || !mounted) return null;
    final s = WaaiyaScope.of(context).state;
    switch (call.arguments) {
      case 'start':
        if (!s.filter.running) await runAction(context, (b) => b.startFilter());
      case 'stop':
        if (s.filter.running) await runAction(context, (b) => b.stopFilter());
    }
    return null;
  }

  void _update(AppLocalizations l, AppState s) {
    final menu = <String, Object?>{
      'tooltip': l.appName,
      'open': l.trayOpen,
      'start': l.powerStartCd,
      'stop': l.powerStopCd,
      'quit': l.trayQuit,
      'on': s.filter.running,
      'rtl': Directionality.of(context) == TextDirection.rtl,
    };
    if (_sent != null && mapEquals(_sent, menu)) return;
    _sent = menu;
    widget.channel.invokeMethod<void>('update', menu).catchError((Object _) {}); // no runner side (tests): nothing
  }

  @override
  Widget build(BuildContext context) {
    final s = WaaiyaScope.of(context).state;
    if (s.capabilities.tray) _update(AppLocalizations.of(context), s);
    return widget.child;
  }
}
