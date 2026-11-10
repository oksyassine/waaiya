import 'package:flutter/widgets.dart';
import 'package:waaiya_ui/waaiya_ui.dart';

/// Entry point of the Android app's Flutter screens (UiActivity). The backend is the platform channel that
/// UiBridge.kt implements over the existing Kotlin code.
void main() => runApp(WaaiyaApp(backend: ChannelBackend()));
