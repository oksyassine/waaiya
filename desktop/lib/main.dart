import 'package:flutter/widgets.dart';
import 'package:waaiya_ui/waaiya_ui.dart';

import 'desktop_backend.dart';

/// Waaiya on Windows and Linux (later macOS): the shared screens over [DesktopBackend].
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(WaaiyaApp(backend: await DesktopBackend.open()));
}
