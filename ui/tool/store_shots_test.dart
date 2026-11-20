// Screenshots of the Windows app for the Microsoft Store listing (desktop/windows/msix/STORE_LISTING.md), rendered
// here with real fonts (Roboto, Noto Naskh Arabic from the Flutter checkout, Material icons), not on a PC:
//
//   cd ui && for l in en fr ar; do flutter test tool/store_shots_test.dart --dart-define=SHOTS=<out dir> \
//       --dart-define=LANG=$l [--dart-define=ARABIC_FONT_DIR=<dir with Amiri-Regular.ttf, Amiri-Bold.ttf>]; done
//
// One language per run: the test renderer does not fall back from one font to another, so for Arabic the app's
// font family (Roboto) is filled with Amiri (Arabic and Latin, SIL OFL) instead.
//
// 1366x768 window at 2x = 2732x1536 PNGs (the Store takes 1366x768 up to 3840x2160), per language and page.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:waaiya_ui/waaiya_ui.dart';

const out = String.fromEnvironment('SHOTS');
const lang = String.fromEnvironment('LANG', defaultValue: 'en');
const arabicDir = String.fromEnvironment('ARABIC_FONT_DIR');

Future<void> loadFont(String family, List<String> files) async {
  final l = FontLoader(family);
  for (final f in files) {
    l.addFont(Future.value(ByteData.sublistView(File(f).readAsBytesSync())));
  }
  await l.load();
}

void main() {
  final flutter = File(Platform.resolvedExecutable).parent.parent.parent.parent.parent.parent.path; // .../flutter
  setUpAll(() async {
    final mat = '$flutter/bin/cache/artifacts/material_fonts';
    final home = Platform.environment['HOME'] ?? '';
    final ar = arabicDir.isNotEmpty ? arabicDir : '$home/.fonts';
    await loadFont(
      'Roboto',
      lang == 'ar'
          ? ['$ar/Amiri-Regular.ttf', '$ar/Amiri-Bold.ttf']
          : ['$mat/Roboto-Regular.ttf', '$mat/Roboto-Medium.ttf', '$mat/Roboto-Bold.ttf'],
    );
    await loadFont('MaterialIcons', ['$mat/MaterialIcons-Regular.otf']);
  });

  {
    testWidgets('store screenshots $lang', (tester) async {
      tester.view.physicalSize = const Size(2732, 1536);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      final key = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: key,
          child: WaaiyaApp(
            backend: MemoryBackend(
              initial: AppState(
                platform: 'windows',
                version: '0.2.13',
                language: lang,
                settings: const WaaiyaSettings(gender: 'man'),
                filter: const FilterInfo(state: FilterState.filtering, delayMs: 0, autostart: true),
                setup: const SetupInfo(originalsMuted: true, consentSkipped: true),
                blur: const BlurInfo(overlayAllowed: true, touchPassThrough: true),
                detectorModel: true,
                capabilities: const Capabilities(
                  womenSinging: true,
                  autostart: true,
                  screenBlur: true,
                  blurStandalone: true,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (final page in ['filter', 'screen', 'settings']) {
        final nav = find.byKey(Key('nav_$page'));
        if (nav.evaluate().isNotEmpty) {
          await tester.tap(nav);
          await tester.pumpAndSettle();
        }
        await tester.runAsync(() async {
          final b = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
          final img = await b.toImage(pixelRatio: 2);
          final png = await img.toByteData(format: ui.ImageByteFormat.png);
          Directory(out).createSync(recursive: true);
          File('$out/$lang-$page.png').writeAsBytesSync(png!.buffer.asUint8List());
        });
      }
    });
  }
}
